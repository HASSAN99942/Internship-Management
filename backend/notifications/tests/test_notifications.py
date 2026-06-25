from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from applications import services as app_services
from applications.tests.utils import (
    make_company,
    make_published_offer,
    make_student,
    make_teacher,
)
from evaluations import services as eval_services
from internships import services as int_services
from internships.tests.utils import make_active_internship, make_pending_internship
from messaging import services as msg_services
from messaging.models import MessageThread
from notifications import services
from notifications.models import Notification


def _types(user):
    return set(
        Notification.objects.filter(user=user).values_list("type", flat=True)
    )


class NotifyHelperTests(APITestCase):
    def test_notify_creates_for_recipient(self):
        user = make_student()
        services.notify(user=user, type="new_message", payload={"message": "hi"})
        self.assertEqual(Notification.objects.filter(user=user).count(), 1)


class EmissionTests(APITestCase):
    def test_apply_notifies_company_not_student(self):
        company = make_company()
        student = make_student()
        offer = make_published_offer(company)
        app_services.apply_to_offer(
            student=student, offer=offer, data={"cover_message": "hi"}
        )
        self.assertIn("application_received", _types(company))
        self.assertEqual(_types(student), set())

    def test_accept_notifies_student_and_teacher_not_company(self):
        # make_pending_internship applies + accepts (assigning the teacher).
        internship, student, company, teacher = make_pending_internship()
        self.assertIn("application_accepted", _types(student))
        self.assertIn("agreement_to_validate", _types(teacher))
        self.assertNotIn("application_accepted", _types(company))
        self.assertNotIn("agreement_to_validate", _types(company))

    def test_reject_notifies_student(self):
        company = make_company()
        student = make_student()
        offer = make_published_offer(company)
        application = app_services.apply_to_offer(
            student=student, offer=offer, data={"cover_message": "hi"}
        )
        app_services.reject_application(application=application)
        self.assertIn("application_rejected", _types(student))

    def test_validate_internship_notifies_student_and_company_not_teacher(self):
        internship, student, company, teacher = make_pending_internship()
        int_services.validate_internship(internship=internship, by_user=teacher)
        self.assertIn("internship_activated", _types(student))
        self.assertIn("internship_activated", _types(company))
        self.assertNotIn("internship_activated", _types(teacher))

    def test_task_lifecycle_notifications(self):
        internship, student, company, teacher = make_active_internship()
        task = int_services.create_task(
            internship=internship, by_user=company, data={"title": "T"}
        )
        self.assertIn("task_assigned", _types(student))

        int_services.submit_task(task=task, note="done")
        # supervisors notified, student (actor) not for the submit event
        self.assertIn("task_submitted", _types(company))
        self.assertIn("task_submitted", _types(teacher))
        self.assertNotIn("task_submitted", _types(student))

        int_services.validate_task(task=task)
        self.assertIn("task_validated", _types(student))

    def test_report_notifications(self):
        internship, student, company, teacher = make_active_internship()
        report = int_services.submit_report(
            internship=internship,
            by_student=student,
            data={"title": "R", "content": "c", "period": "W1"},
        )
        self.assertIn("report_submitted", _types(company))
        self.assertIn("report_submitted", _types(teacher))

        int_services.request_report_changes(report=report, feedback="more")
        self.assertIn("report_changes_requested", _types(student))

    def test_new_message_notifies_other_party_not_sender(self):
        internship, student, company, teacher = make_active_internship()
        thread = MessageThread.objects.get(internship=internship)
        msg_services.send_message(thread=thread, sender=student, body="hello")
        self.assertIn("new_message", _types(company))
        self.assertIn("new_message", _types(teacher))
        self.assertNotIn("new_message", _types(student))

    def test_evaluation_notifies_student_but_not_on_self_rating(self):
        internship, student, company, teacher = make_active_internship()
        eval_services.submit_evaluation(
            internship=internship,
            evaluator=company,
            evaluator_type="company",
            scores={"a": 5},
        )
        self.assertIn("evaluation_submitted", _types(student))

        # A student's own rating must not notify the student (they are the actor).
        before = Notification.objects.filter(user=student).count()
        eval_services.submit_evaluation(
            internship=internship,
            evaluator=student,
            evaluator_type="student",
            scores={"b": 4},
        )
        after = Notification.objects.filter(user=student).count()
        self.assertEqual(before, after)


class EndpointTests(APITestCase):
    def setUp(self):
        self.u1 = make_student()
        self.u2 = make_student()
        services.notify(user=self.u1, type="new_message", payload={"message": "1"})
        services.notify(user=self.u1, type="new_message", payload={"message": "2"})
        self.other = services.notify(
            user=self.u2, type="new_message", payload={"message": "x"}
        )

    def test_list_is_owner_scoped(self):
        self.client.force_authenticate(self.u1)
        res = self.client.get(reverse("notification-list"))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["count"], 2)

    def test_unread_count(self):
        self.client.force_authenticate(self.u1)
        res = self.client.get(reverse("notification-unread-count"))
        self.assertEqual(res.data["unread"], 2)

    def test_cannot_mark_others_notification(self):
        self.client.force_authenticate(self.u1)
        res = self.client.post(
            reverse("notification-read", args=[self.other.id])
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
        self.other.refresh_from_db()
        self.assertFalse(self.other.is_read)

    def test_mark_all_read_is_owner_scoped(self):
        self.client.force_authenticate(self.u1)
        res = self.client.post(reverse("notification-read-all"))
        self.assertEqual(res.data["marked_read"], 2)
        # u2's notification is untouched.
        self.other.refresh_from_db()
        self.assertFalse(self.other.is_read)
