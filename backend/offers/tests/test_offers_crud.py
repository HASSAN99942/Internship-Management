from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from offers.models import Offer

from .factories import VALID_OFFER, make_company, make_offer, make_student


class OfferCreateTests(APITestCase):
    def setUp(self):
        self.url = reverse("offer-list-create")
        self.company = make_company()
        self.student = make_student()

    def test_company_creates_offer_as_draft(self):
        self.client.force_authenticate(self.company)
        res = self.client.post(self.url, VALID_OFFER, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data["status"], "draft")
        self.assertEqual(res.data["company"]["company_name"], "Acme")
        offer = Offer.objects.get(id=res.data["id"])
        self.assertEqual(offer.company, self.company)

    def test_non_company_cannot_create_offer(self):
        self.client.force_authenticate(self.student)
        res = self.client.post(self.url, VALID_OFFER, format="json")
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(Offer.objects.count(), 0)

    def test_unauthenticated_cannot_create_offer(self):
        res = self.client.post(self.url, VALID_OFFER, format="json")
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_company_not_settable_via_body(self):
        # Even if a client sends company/status, they are ignored.
        self.client.force_authenticate(self.company)
        payload = {**VALID_OFFER, "company": 999, "status": "published"}
        res = self.client.post(self.url, payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data["status"], "draft")
        self.assertEqual(res.data["company"]["id"], self.company.id)

    def test_invalid_duration_rejected(self):
        self.client.force_authenticate(self.company)
        res = self.client.post(
            self.url, {**VALID_OFFER, "duration_weeks": 0}, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)


class OfferUpdateDeleteTests(APITestCase):
    def setUp(self):
        self.owner = make_company(email="owner@example.com", name="Owner Co")
        self.other = make_company(email="other@example.com", name="Other Co")
        self.offer = make_offer(self.owner)
        self.detail_url = reverse("offer-detail", args=[self.offer.id])

    def test_owner_can_update(self):
        self.client.force_authenticate(self.owner)
        res = self.client.patch(
            self.detail_url, {"title": "Updated title"}, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.offer.refresh_from_db()
        self.assertEqual(self.offer.title, "Updated title")

    def test_other_company_cannot_update(self):
        self.client.force_authenticate(self.other)
        res = self.client.patch(
            self.detail_url, {"title": "Hijacked"}, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_owner_can_delete(self):
        self.client.force_authenticate(self.owner)
        res = self.client.delete(self.detail_url)
        self.assertEqual(res.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Offer.objects.filter(id=self.offer.id).exists())

    def test_other_company_cannot_delete(self):
        self.client.force_authenticate(self.other)
        res = self.client.delete(self.detail_url)
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
        self.assertTrue(Offer.objects.filter(id=self.offer.id).exists())

    def test_admin_can_update_any_offer(self):
        from accounts.models import User

        admin = User.objects.create_superuser(
            email="admin@example.com", password="Str0ngPass!23"
        )
        self.client.force_authenticate(admin)
        res = self.client.patch(
            self.detail_url, {"title": "By admin"}, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.offer.refresh_from_db()
        self.assertEqual(self.offer.title, "By admin")
