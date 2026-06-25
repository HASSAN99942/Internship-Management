"""Tests for the teacher list and the (now removed) direct supervisor picker.

Supervision moved to a mutual-consent request/validate flow (see
``test_supervision.py``). As a result:
- ``GET /teachers/`` now requires authentication (used inside the app, not on
  the public signup page).
- A student can no longer set their supervisor at registration or via
  ``PATCH /me/`` — that goes through supervision requests.
"""

from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.models import User
from accounts.services import register_user

PASSWORD = "Str0ngPass!23"


class TeacherListTests(APITestCase):
    def setUp(self):
        self.url = reverse("teacher-list")
        self.teacher = register_user(
            email="prof@example.com",
            password=PASSWORD,
            role="teacher",
            first_name="Tara",
            last_name="Prof",
            profile={"department": "CS"},
        )
        self.student = register_user(
            email="student@example.com",
            password=PASSWORD,
            role="student",
            profile={"school": "ENSA", "program": "SE", "level": "M1"},
        )
        # A non-teacher should never appear in the picker.
        register_user(
            email="co@example.com",
            password=PASSWORD,
            role="company",
            profile={"company_name": "Acme"},
        )

    def test_teacher_list_requires_authentication(self):
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_authenticated_user_lists_only_teachers(self):
        self.client.force_authenticate(user=self.student)
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        ids = [t["id"] for t in res.data]
        self.assertEqual(ids, [self.teacher.id])
        self.assertEqual(res.data[0]["full_name"], "Tara Prof")
        self.assertEqual(res.data[0]["department"], "CS")


class SupervisorNotSetDirectlyTests(APITestCase):
    """The supervisor is no longer settable at signup or through /me/."""

    def setUp(self):
        self.me_url = reverse("me")
        self.register_url = reverse("register")
        self.teacher = register_user(
            email="prof@example.com",
            password=PASSWORD,
            role="teacher",
            profile={"department": "CS"},
        )
        self.student = register_user(
            email="student@example.com",
            password=PASSWORD,
            role="student",
            profile={"school": "ENSA", "program": "SE", "level": "M1"},
        )

    def test_registration_ignores_assigned_teacher(self):
        res = self.client.post(
            self.register_url,
            {
                "email": "new@example.com",
                "password": PASSWORD,
                "role": "student",
                "profile": {
                    "school": "ENSA",
                    "program": "SE",
                    "level": "M1",
                    "assigned_teacher": self.teacher.id,
                },
            },
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertIsNone(res.data["profile"]["assigned_teacher"])
        created = User.objects.get(email="new@example.com")
        self.assertIsNone(created.student_profile.assigned_teacher_id)

    def test_me_patch_does_not_set_supervisor(self):
        self.client.force_authenticate(user=self.student)
        res = self.client.patch(
            self.me_url,
            {"profile": {"assigned_teacher": self.teacher.id}},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIsNone(res.data["profile"]["assigned_teacher"])
        self.student.refresh_from_db()
        self.assertIsNone(self.student.student_profile.assigned_teacher_id)
