from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.models import (
    CompanyProfile,
    StudentProfile,
    TeacherProfile,
    User,
)


class RegistrationTests(APITestCase):
    def setUp(self):
        self.url = reverse("register")

    def test_register_student_creates_user_and_profile(self):
        payload = {
            "email": "stu@example.com",
            "password": "Str0ngPass!23",
            "first_name": "Sam",
            "last_name": "Student",
            "role": "student",
            "profile": {
                "school": "ENSA",
                "program": "Software Engineering",
                "level": "M1",
            },
        }
        res = self.client.post(self.url, payload, format="json")

        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        user = User.objects.get(email="stu@example.com")
        self.assertEqual(user.role, "student")
        self.assertTrue(StudentProfile.objects.filter(user=user).exists())
        self.assertEqual(user.student_profile.school, "ENSA")
        # Password must be hashed, never stored or echoed in plaintext.
        self.assertNotEqual(user.password, "Str0ngPass!23")
        self.assertNotIn("password", res.data)

    def test_register_company_creates_profile(self):
        payload = {
            "email": "co@example.com",
            "password": "Str0ngPass!23",
            "role": "company",
            "profile": {"company_name": "Acme Inc"},
        }
        res = self.client.post(self.url, payload, format="json")

        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        user = User.objects.get(email="co@example.com")
        self.assertTrue(CompanyProfile.objects.filter(user=user).exists())
        self.assertEqual(user.company_profile.company_name, "Acme Inc")

    def test_register_teacher_creates_profile(self):
        payload = {
            "email": "teach@example.com",
            "password": "Str0ngPass!23",
            "role": "teacher",
            "profile": {"department": "Computer Science"},
        }
        res = self.client.post(self.url, payload, format="json")

        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        user = User.objects.get(email="teach@example.com")
        self.assertTrue(TeacherProfile.objects.filter(user=user).exists())

    def test_duplicate_email_rejected(self):
        payload = {
            "email": "dup@example.com",
            "password": "Str0ngPass!23",
            "role": "teacher",
            "profile": {"department": "Math"},
        }
        first = self.client.post(self.url, payload, format="json")
        self.assertEqual(first.status_code, status.HTTP_201_CREATED)

        second = self.client.post(self.url, payload, format="json")
        self.assertEqual(second.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(User.objects.filter(email="dup@example.com").count(), 1)

    def test_duplicate_email_case_insensitive(self):
        self.client.post(
            self.url,
            {
                "email": "Case@example.com",
                "password": "Str0ngPass!23",
                "role": "teacher",
                "profile": {"department": "Math"},
            },
            format="json",
        )
        res = self.client.post(
            self.url,
            {
                "email": "case@example.com",
                "password": "Str0ngPass!23",
                "role": "teacher",
                "profile": {"department": "Math"},
            },
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_admin_role_cannot_self_register(self):
        res = self.client.post(
            self.url,
            {
                "email": "wannabe-admin@example.com",
                "password": "Str0ngPass!23",
                "role": "admin",
                "profile": {},
            },
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(
            User.objects.filter(email="wannabe-admin@example.com").exists()
        )

    def test_missing_role_profile_fields_rejected(self):
        # Student requires school/program/level.
        res = self.client.post(
            self.url,
            {
                "email": "incomplete@example.com",
                "password": "Str0ngPass!23",
                "role": "student",
                "profile": {"school": "ENSA"},
            },
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(
            User.objects.filter(email="incomplete@example.com").exists()
        )

    def test_weak_password_rejected(self):
        res = self.client.post(
            self.url,
            {
                "email": "weak@example.com",
                "password": "123",
                "role": "teacher",
                "profile": {"department": "Math"},
            },
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(User.objects.filter(email="weak@example.com").exists())
