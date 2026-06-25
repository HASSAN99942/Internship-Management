from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from applications.models import Application
from internships.models import Internship
from messaging.models import MessageThread

from .utils import make_company, make_published_offer, make_student, make_teacher


class DecisionTests(APITestCase):
    def setUp(self):
        self.company = make_company()
        self.other_company = make_company()
        self.student = make_student()
        self.teacher = make_teacher()
        profile = self.student.student_profile
        profile.assigned_teacher = self.teacher
        profile.save()

        self.offer = make_published_offer(self.company, positions=2)
        self.client.force_authenticate(self.student)
        self.client.post(
            reverse("offer-apply", args=[self.offer.id]),
            {"cover_message": "Hi"},
            format="multipart",
        )
        self.client.force_authenticate(None)
        self.application = Application.objects.get(student=self.student)

    def test_accept_creates_internship_and_thread(self):
        self.client.force_authenticate(self.company)
        res = self.client.post(
            reverse("application-accept", args=[self.application.id])
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)

        self.application.refresh_from_db()
        self.assertEqual(self.application.status, "accepted")
        self.assertIsNotNone(self.application.decided_at)

        internship = Internship.objects.get(application=self.application)
        self.assertEqual(internship.status, "pending_academic_validation")
        self.assertEqual(internship.teacher, self.teacher)
        self.assertEqual(internship.company, self.company)
        self.assertTrue(
            MessageThread.objects.filter(internship=internship).exists()
        )

    def test_reject_sets_rejected(self):
        self.client.force_authenticate(self.company)
        res = self.client.post(
            reverse("application-reject", args=[self.application.id])
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.application.refresh_from_db()
        self.assertEqual(self.application.status, "rejected")
        self.assertIsNotNone(self.application.decided_at)
        self.assertFalse(
            Internship.objects.filter(application=self.application).exists()
        )

    def test_only_owning_company_can_accept(self):
        self.client.force_authenticate(self.other_company)
        res = self.client.post(
            reverse("application-accept", args=[self.application.id])
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

        self.client.force_authenticate(self.student)
        res = self.client.post(
            reverse("application-accept", args=[self.application.id])
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_cannot_accept_non_pending(self):
        self.client.force_authenticate(self.student)
        self.client.post(
            reverse("application-withdraw", args=[self.application.id])
        )
        self.client.force_authenticate(self.company)
        res = self.client.post(
            reverse("application-accept", args=[self.application.id])
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_withdraw_by_owner_while_pending(self):
        self.client.force_authenticate(self.student)
        res = self.client.post(
            reverse("application-withdraw", args=[self.application.id])
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.application.refresh_from_db()
        self.assertEqual(self.application.status, "withdrawn")

    def test_withdraw_non_owner_forbidden(self):
        other = make_student()
        self.client.force_authenticate(other)
        res = self.client.post(
            reverse("application-withdraw", args=[self.application.id])
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
