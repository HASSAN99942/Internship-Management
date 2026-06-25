from django.contrib.auth import get_user_model
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

User = get_user_model()


class InternshipTests(APITestCase):
    def setUp(self):
        self.company = make_company()
        self.student = make_student()
        self.teacher = make_teacher()
        self.other_teacher = make_teacher()
        profile = self.student.student_profile
        profile.assigned_teacher = self.teacher
        profile.save()

        self.offer = make_published_offer(self.company, positions=3)
        self.client.force_authenticate(self.student)
        self.client.post(
            reverse("offer-apply", args=[self.offer.id]),
            {"cover_message": "Hi"},
            format="multipart",
        )
        self.client.force_authenticate(None)
        self.application = Application.objects.get(student=self.student)
        self.internship = accept_application(application=self.application)

    def test_internship_created_pending_with_teacher(self):
        self.assertEqual(self.internship.status, "pending_academic_validation")
        self.assertEqual(self.internship.teacher, self.teacher)

    def test_assigned_teacher_validates(self):
        self.client.force_authenticate(self.teacher)
        res = self.client.post(
            reverse("internship-validate", args=[self.internship.id])
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.internship.refresh_from_db()
        self.assertEqual(self.internship.status, "active")

    def test_admin_can_validate(self):
        admin = User.objects.create_superuser(
            email="admin@example.com", password="Str0ngPass!23"
        )
        self.client.force_authenticate(admin)
        res = self.client.post(
            reverse("internship-validate", args=[self.internship.id])
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.internship.refresh_from_db()
        self.assertEqual(self.internship.status, "active")

    def test_other_teacher_cannot_validate(self):
        self.client.force_authenticate(self.other_teacher)
        res = self.client.post(
            reverse("internship-validate", args=[self.internship.id])
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_cannot_validate_non_pending(self):
        self.client.force_authenticate(self.teacher)
        self.client.post(reverse("internship-validate", args=[self.internship.id]))
        res = self.client.post(
            reverse("internship-validate", args=[self.internship.id])
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_list_is_role_scoped(self):
        url = reverse("internship-list")

        self.client.force_authenticate(self.student)
        self.assertEqual(self.client.get(url).data["count"], 1)

        self.client.force_authenticate(self.company)
        self.assertEqual(self.client.get(url).data["count"], 1)

        self.client.force_authenticate(self.teacher)
        self.assertEqual(self.client.get(url).data["count"], 1)

        self.client.force_authenticate(self.other_teacher)
        self.assertEqual(self.client.get(url).data["count"], 0)

    def test_detail_visibility(self):
        url = reverse("internship-detail", args=[self.internship.id])

        self.client.force_authenticate(self.student)
        self.assertEqual(self.client.get(url).status_code, status.HTTP_200_OK)

        self.client.force_authenticate(self.other_teacher)
        self.assertEqual(
            self.client.get(url).status_code, status.HTTP_403_FORBIDDEN
        )
