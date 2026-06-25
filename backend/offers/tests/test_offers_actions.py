from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from offers.models import Offer

from .factories import make_company, make_offer


class OfferActionTests(APITestCase):
    def setUp(self):
        self.owner = make_company(email="owner@example.com")
        self.other = make_company(email="other@example.com")

    def test_publish_moves_draft_to_published(self):
        offer = make_offer(self.owner, status=Offer.Status.DRAFT)
        self.client.force_authenticate(self.owner)
        res = self.client.post(reverse("offer-publish", args=[offer.id]))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["status"], "published")
        offer.refresh_from_db()
        self.assertEqual(offer.status, Offer.Status.PUBLISHED)

    def test_publish_non_draft_rejected(self):
        offer = make_offer(self.owner, status=Offer.Status.PUBLISHED)
        self.client.force_authenticate(self.owner)
        res = self.client.post(reverse("offer-publish", args=[offer.id]))
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_close_sets_status_closed(self):
        offer = make_offer(self.owner, status=Offer.Status.PUBLISHED)
        self.client.force_authenticate(self.owner)
        res = self.client.post(reverse("offer-close", args=[offer.id]))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["status"], "closed")
        offer.refresh_from_db()
        self.assertFalse(offer.is_open())

    def test_close_already_closed_rejected(self):
        offer = make_offer(self.owner, status=Offer.Status.CLOSED)
        self.client.force_authenticate(self.owner)
        res = self.client.post(reverse("offer-close", args=[offer.id]))
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_other_company_cannot_publish(self):
        offer = make_offer(self.owner, status=Offer.Status.DRAFT)
        self.client.force_authenticate(self.other)
        res = self.client.post(reverse("offer-publish", args=[offer.id]))
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
        offer.refresh_from_db()
        self.assertEqual(offer.status, Offer.Status.DRAFT)

    def test_other_company_cannot_close(self):
        offer = make_offer(self.owner, status=Offer.Status.PUBLISHED)
        self.client.force_authenticate(self.other)
        res = self.client.post(reverse("offer-close", args=[offer.id]))
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
