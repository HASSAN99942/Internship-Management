from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from applications.tests.utils import (
    make_company,
    make_published_offer,
    make_student,
    make_teacher,
)

User = get_user_model()


class AdminStatsTests(APITestCase):
    def setUp(self):
        self.admin = User.objects.create_superuser(
            email="admin@example.com", password="Str0ngPass!23"
        )
        self.company = make_company()
        self.student_a = make_student()
        self.student_b = make_student()
        self.teacher = make_teacher()
        make_published_offer(self.company)

    def test_stats_counts(self):
        self.client.force_authenticate(self.admin)
        res = self.client.get(reverse("admin-stats"))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["users_by_role"]["student"], 2)
        self.assertEqual(res.data["users_by_role"]["company"], 1)
        self.assertEqual(res.data["users_by_role"]["teacher"], 1)
        self.assertEqual(res.data["users_by_role"]["admin"], 1)
        self.assertEqual(res.data["offers_by_status"]["published"], 1)
        self.assertIn("active_internships", res.data["totals"])

    def test_stats_forbidden_for_non_admin(self):
        self.client.force_authenticate(self.company)
        res = self.client.get(reverse("admin-stats"))
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)


class AssignTeacherTests(APITestCase):
    def setUp(self):
        self.admin = User.objects.create_superuser(
            email="admin@example.com", password="Str0ngPass!23"
        )
        self.company = make_company()
        self.student = make_student()
        self.teacher = make_teacher()
        self.url = reverse("admin-assign-teacher")

    def test_admin_assigns_teacher(self):
        self.client.force_authenticate(self.admin)
        res = self.client.post(
            self.url,
            {"student_id": self.student.id, "teacher_id": self.teacher.id},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.student.student_profile.refresh_from_db()
        self.assertEqual(
            self.student.student_profile.assigned_teacher_id, self.teacher.id
        )

    def test_invalid_teacher_role_rejected(self):
        self.client.force_authenticate(self.admin)
        res = self.client.post(
            self.url,
            {"student_id": self.student.id, "teacher_id": self.company.id},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_forbidden_for_non_admin(self):
        self.client.force_authenticate(self.teacher)
        res = self.client.post(
            self.url,
            {"student_id": self.student.id, "teacher_id": self.teacher.id},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
