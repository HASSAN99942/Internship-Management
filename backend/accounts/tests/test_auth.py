from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.services import register_user


class AuthFlowTests(APITestCase):
    def setUp(self):
        self.login_url = reverse("login")
        self.refresh_url = reverse("token_refresh")
        self.logout_url = reverse("logout")
        self.me_url = reverse("me")
        self.password = "Str0ngPass!23"
        self.user = register_user(
            email="flow@example.com",
            password=self.password,
            role="teacher",
            profile={"department": "Physics"},
        )

    def test_login_returns_tokens_and_role(self):
        res = self.client.post(
            self.login_url,
            {"email": "flow@example.com", "password": self.password},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn("access", res.data)
        self.assertIn("refresh", res.data)
        self.assertEqual(res.data["role"], "teacher")

    def test_login_wrong_password_rejected(self):
        res = self.client.post(
            self.login_url,
            {"email": "flow@example.com", "password": "wrong"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_refresh_returns_new_access_token(self):
        login = self.client.post(
            self.login_url,
            {"email": "flow@example.com", "password": self.password},
            format="json",
        )
        refresh = login.data["refresh"]

        res = self.client.post(
            self.refresh_url, {"refresh": refresh}, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn("access", res.data)

    def test_access_token_authorizes_me(self):
        login = self.client.post(
            self.login_url,
            {"email": "flow@example.com", "password": self.password},
            format="json",
        )
        access = login.data["access"]

        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
        res = self.client.get(self.me_url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["email"], "flow@example.com")

    def test_logout_blacklists_refresh_token(self):
        login = self.client.post(
            self.login_url,
            {"email": "flow@example.com", "password": self.password},
            format="json",
        )
        access = login.data["access"]
        refresh = login.data["refresh"]

        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
        logout = self.client.post(
            self.logout_url, {"refresh": refresh}, format="json"
        )
        self.assertEqual(logout.status_code, status.HTTP_205_RESET_CONTENT)

        # The blacklisted refresh token can no longer be used.
        self.client.credentials()
        res = self.client.post(
            self.refresh_url, {"refresh": refresh}, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)
