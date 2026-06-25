from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from applications.models import Application
from applications.services import accept_application
from applications.tests.utils import (
    make_company,
    make_published_offer,
    make_student,
    make_teacher,
)
from messaging.models import MessageThread


def build_thread():
    """Create an accepted internship (which creates its thread) and return parts.

    Returns (thread, student, company, teacher).
    """
    company = make_company()
    student = make_student()
    teacher = make_teacher()
    profile = student.student_profile
    profile.assigned_teacher = teacher
    profile.save()

    offer = make_published_offer(company, positions=3)
    Application.objects.create(offer=offer, student=student, cover_message="Hi")
    application = Application.objects.get(offer=offer, student=student)
    internship = accept_application(application=application)
    return internship.thread, student, company, teacher


class MessagingTests(APITestCase):
    def setUp(self):
        self.thread, self.student, self.company, self.teacher = build_thread()
        self.outsider = make_student()
        self.messages_url = reverse("thread-messages", args=[self.thread.id])
        self.read_url = reverse("thread-read", args=[self.thread.id])
        self.list_url = reverse("thread-list")

    # --- send / read ----------------------------------------------------- #
    def test_participant_sends_and_reads(self):
        self.client.force_authenticate(self.student)
        res = self.client.post(
            self.messages_url, {"body": "Hello team"}, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data["body"], "Hello team")
        self.assertEqual(res.data["sender"]["id"], self.student.id)

        self.client.force_authenticate(self.company)
        listed = self.client.get(self.messages_url)
        self.assertEqual(listed.status_code, status.HTTP_200_OK)
        self.assertEqual(listed.data["count"], 1)
        self.assertEqual(listed.data["results"][0]["body"], "Hello team")

    def test_non_participant_forbidden_read_and_send(self):
        self.client.force_authenticate(self.outsider)
        self.assertEqual(
            self.client.get(self.messages_url).status_code,
            status.HTTP_403_FORBIDDEN,
        )
        self.assertEqual(
            self.client.post(
                self.messages_url, {"body": "intruding"}, format="json"
            ).status_code,
            status.HTTP_403_FORBIDDEN,
        )

    def test_empty_body_rejected(self):
        self.client.force_authenticate(self.student)
        res = self.client.post(self.messages_url, {"body": "   "}, format="json")
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    # --- read state ------------------------------------------------------ #
    def test_mark_read_clears_caller_unread_not_other_party(self):
        # student and company each send one message
        self.client.force_authenticate(self.student)
        self.client.post(self.messages_url, {"body": "from student"}, format="json")
        self.client.force_authenticate(self.company)
        self.client.post(self.messages_url, {"body": "from company"}, format="json")

        # student marks read -> only the company's message flips
        self.client.force_authenticate(self.student)
        res = self.client.post(self.read_url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)

        # student now has 0 unread; company still has 1 (the student's message)
        self.client.force_authenticate(self.student)
        student_threads = self.client.get(self.list_url).data
        self.assertEqual(student_threads[0]["unread_count"], 0)

        self.client.force_authenticate(self.company)
        company_threads = self.client.get(self.list_url).data
        self.assertEqual(company_threads[0]["unread_count"], 1)

    # --- thread list ----------------------------------------------------- #
    def test_thread_list_preview_and_scoping(self):
        self.client.force_authenticate(self.student)
        self.client.post(self.messages_url, {"body": "latest line"}, format="json")

        data = self.client.get(self.list_url).data
        self.assertEqual(len(data), 1)
        self.assertEqual(data[0]["last_message"], "latest line")
        self.assertGreaterEqual(len(data[0]["participants"]), 2)

        # an outsider sees no threads
        self.client.force_authenticate(self.outsider)
        self.assertEqual(len(self.client.get(self.list_url).data), 0)

    def test_thread_detail_for_participant(self):
        self.client.force_authenticate(self.teacher)
        res = self.client.get(reverse("thread-detail", args=[self.thread.id]))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["internship_id"], self.thread.internship_id)

    def test_thread_detail_forbidden_for_outsider(self):
        self.client.force_authenticate(self.outsider)
        res = self.client.get(reverse("thread-detail", args=[self.thread.id]))
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
