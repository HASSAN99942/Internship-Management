from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from applications.tests.utils import make_company, make_student, make_teacher

User = get_user_model()


class AssignTeacherTests(APITestCase):
    def setUp(self):
        self.t1 = make_teacher()
        self.t2 = make_teacher()
        self.admin = User.objects.create_superuser(
            email="admin_assign@example.com", password="Str0ngPass!23"
        )
        self.company = make_company()
        self.s1 = make_student()  # unassigned
        self.s2 = make_student()  # assigned to t2
        p2 = self.s2.student_profile
        p2.assigned_teacher = self.t2
        p2.save()

        self.list_url = reverse("student-list")

    def _assign_url(self, student):
        return reverse("student-assign", args=[student.id])

    # --- teacher claim / release ---------------------------------------- #
    def test_teacher_claims_unassigned_student(self):
        self.client.force_authenticate(self.t1)
        res = self.client.patch(
            self._assign_url(self.s1),
            {"assigned_teacher": self.t1.id},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.s1.student_profile.refresh_from_db()
        self.assertEqual(self.s1.student_profile.assigned_teacher_id, self.t1.id)

    def test_teacher_releases_own_student(self):
        self.s1.student_profile.assigned_teacher = self.t1
        self.s1.student_profile.save()
        self.client.force_authenticate(self.t1)
        res = self.client.patch(
            self._assign_url(self.s1), {"assigned_teacher": None}, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.s1.student_profile.refresh_from_db()
        self.assertIsNone(self.s1.student_profile.assigned_teacher_id)

    def test_teacher_cannot_claim_other_teachers_student(self):
        self.client.force_authenticate(self.t1)
        res = self.client.patch(
            self._assign_url(self.s2),
            {"assigned_teacher": self.t1.id},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
        self.s2.student_profile.refresh_from_db()
        self.assertEqual(self.s2.student_profile.assigned_teacher_id, self.t2.id)

    def test_teacher_cannot_assign_to_a_different_teacher(self):
        self.client.force_authenticate(self.t1)
        res = self.client.patch(
            self._assign_url(self.s1),
            {"assigned_teacher": self.t2.id},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    # --- admin ----------------------------------------------------------- #
    def test_admin_can_assign_anyone(self):
        self.client.force_authenticate(self.admin)
        res = self.client.patch(
            self._assign_url(self.s1),
            {"assigned_teacher": self.t2.id},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.s1.student_profile.refresh_from_db()
        self.assertEqual(self.s1.student_profile.assigned_teacher_id, self.t2.id)

    def test_admin_can_reassign(self):
        self.client.force_authenticate(self.admin)
        res = self.client.patch(
            self._assign_url(self.s2),
            {"assigned_teacher": self.t1.id},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.s2.student_profile.refresh_from_db()
        self.assertEqual(self.s2.student_profile.assigned_teacher_id, self.t1.id)

    # --- validation / errors -------------------------------------------- #
    def test_assigning_non_teacher_is_rejected(self):
        self.client.force_authenticate(self.admin)
        res = self.client.patch(
            self._assign_url(self.s1),
            {"assigned_teacher": self.s2.id},  # a student, not a teacher
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_404_NOT_FOUND)

    def test_patch_on_non_student_404(self):
        self.client.force_authenticate(self.admin)
        res = self.client.patch(
            reverse("student-assign", args=[self.t1.id]),  # teacher has no profile
            {"assigned_teacher": None},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_404_NOT_FOUND)

    # --- role gating ----------------------------------------------------- #
    def test_student_forbidden(self):
        self.client.force_authenticate(self.s1)
        self.assertEqual(
            self.client.get(self.list_url).status_code, status.HTTP_403_FORBIDDEN
        )
        res = self.client.patch(
            self._assign_url(self.s1), {"assigned_teacher": None}, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_company_forbidden(self):
        self.client.force_authenticate(self.company)
        self.assertEqual(
            self.client.get(self.list_url).status_code, status.HTTP_403_FORBIDDEN
        )

    # --- list scoping ---------------------------------------------------- #
    def test_list_scoping(self):
        # t1 owns s1; s2 belongs to t2 and must be hidden from t1.
        self.s1.student_profile.assigned_teacher = self.t1
        self.s1.student_profile.save()

        self.client.force_authenticate(self.t1)
        ids = [row["id"] for row in self.client.get(self.list_url).data["results"]]
        self.assertIn(self.s1.id, ids)
        self.assertNotIn(self.s2.id, ids)

        self.client.force_authenticate(self.admin)
        admin_ids = [
            row["id"] for row in self.client.get(self.list_url).data["results"]
        ]
        self.assertIn(self.s1.id, admin_ids)
        self.assertIn(self.s2.id, admin_ids)
