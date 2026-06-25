from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from applications.models import Application

from .utils import make_company, make_published_offer, make_student


class ListTests(APITestCase):
    def setUp(self):
        self.c1 = make_company()
        self.c2 = make_company()
        self.s1 = make_student()
        self.s2 = make_student()
        self.o1 = make_published_offer(self.c1, positions=5)
        self.o2 = make_published_offer(self.c2, positions=5)
        self._apply(self.s1, self.o1)
        self._apply(self.s2, self.o2)

    def _apply(self, student, offer):
        self.client.force_authenticate(student)
        self.client.post(
            reverse("offer-apply", args=[offer.id]),
            {"cover_message": "Hi"},
            format="multipart",
        )
        self.client.force_authenticate(None)

    def test_student_sees_only_own(self):
        self.client.force_authenticate(self.s1)
        res = self.client.get(reverse("application-list"))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["count"], 1)
        self.assertEqual(res.data["results"][0]["student"]["id"], self.s1.id)

    def test_company_sees_only_received(self):
        self.client.force_authenticate(self.c1)
        res = self.client.get(reverse("application-list"))
        self.assertEqual(res.data["count"], 1)
        self.assertEqual(res.data["results"][0]["offer"]["id"], self.o1.id)

    def test_detail_visibility(self):
        app = Application.objects.get(student=self.s1)
        url = reverse("application-detail", args=[app.id])

        self.client.force_authenticate(self.s1)
        self.assertEqual(self.client.get(url).status_code, status.HTTP_200_OK)

        self.client.force_authenticate(self.s2)
        self.assertEqual(
            self.client.get(url).status_code, status.HTTP_403_FORBIDDEN
        )

        self.client.force_authenticate(self.c1)
        self.assertEqual(self.client.get(url).status_code, status.HTTP_200_OK)

        self.client.force_authenticate(self.c2)
        self.assertEqual(
            self.client.get(url).status_code, status.HTTP_403_FORBIDDEN
        )
