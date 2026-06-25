from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.services import register_user


class MeEndpointTests(APITestCase):
    def setUp(self):
        self.me_url = reverse("me")
        self.password = "Str0ngPass!23"
        self.student = register_user(
            email="student@example.com",
            password=self.password,
            role="student",
            first_name="Sam",
            profile={"school": "ENSA", "program": "SE", "level": "M1"},
        )
        self.other = register_user(
            email="other@example.com",
            password=self.password,
            role="student",
            profile={"school": "X", "program": "Y", "level": "L3"},
        )

    def _auth(self, user):
        self.client.force_authenticate(user=user)

    def test_me_requires_authentication(self):
        res = self.client.get(self.me_url)
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_me_returns_user_with_profile(self):
        self._auth(self.student)
        res = self.client.get(self.me_url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["email"], "student@example.com")
        self.assertEqual(res.data["role"], "student")
        self.assertEqual(res.data["profile"]["school"], "ENSA")

    def test_patch_updates_own_user_and_profile(self):
        self._auth(self.student)
        res = self.client.patch(
            self.me_url,
            {"first_name": "Samuel", "profile": {"level": "M2"}},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.student.refresh_from_db()
        self.assertEqual(self.student.first_name, "Samuel")
        self.assertEqual(self.student.student_profile.level, "M2")

    def test_patch_only_affects_own_data(self):
        """PATCH /me/ acts on request.user only; another user is untouched."""
        self._auth(self.student)
        before = self.other.first_name
        # Even if a client tries to smuggle another user's id, /me ignores it.
        res = self.client.patch(
            self.me_url,
            {"id": self.other.id, "first_name": "Hacked"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.other.refresh_from_db()
        self.assertEqual(self.other.first_name, before)
        self.assertNotEqual(self.other.first_name, "Hacked")
        # The change applied to the authenticated student instead.
        self.student.refresh_from_db()
        self.assertEqual(self.student.first_name, "Hacked")
