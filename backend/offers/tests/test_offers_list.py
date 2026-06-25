from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from offers.models import Offer

from .factories import make_company, make_offer, make_student, make_teacher


class PublishedListTests(APITestCase):
    def setUp(self):
        self.url = reverse("offer-list-create")
        self.company = make_company()
        self.student = make_student()
        # A mix of statuses; only published should appear in the public list.
        self.published = make_offer(
            self.company, status=Offer.Status.PUBLISHED, title="Published one"
        )
        make_offer(self.company, status=Offer.Status.DRAFT, title="Hidden draft")
        make_offer(self.company, status=Offer.Status.CLOSED, title="Closed one")

    def test_list_returns_only_published(self):
        self.client.force_authenticate(self.student)
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["count"], 1)
        self.assertEqual(res.data["results"][0]["title"], "Published one")

    def test_list_requires_authentication(self):
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_teacher_can_browse(self):
        self.client.force_authenticate(make_teacher())
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["count"], 1)


class FilterTests(APITestCase):
    def setUp(self):
        self.url = reverse("offer-list-create")
        self.c1 = make_company(email="c1@example.com", name="C1")
        self.c2 = make_company(email="c2@example.com", name="C2")
        self.student = make_student()
        make_offer(
            self.c1,
            status=Offer.Status.PUBLISHED,
            title="Python Backend Intern",
            description="Backend engineering role.",
            skills="python, django",
            location="Casablanca",
            duration_weeks=12,
        )
        make_offer(
            self.c2,
            status=Offer.Status.PUBLISHED,
            title="React Frontend Intern",
            description="Frontend engineering role.",
            skills="react, typescript",
            location="Rabat",
            duration_weeks=8,
        )
        self.client.force_authenticate(self.student)

    def test_keyword_filter_matches_title_or_skills(self):
        res = self.client.get(self.url, {"q": "django"})
        self.assertEqual(res.data["count"], 1)
        self.assertEqual(res.data["results"][0]["title"], "Python Backend Intern")

    def test_location_filter(self):
        res = self.client.get(self.url, {"location": "rabat"})
        self.assertEqual(res.data["count"], 1)
        self.assertEqual(res.data["results"][0]["location"], "Rabat")

    def test_duration_filter(self):
        res = self.client.get(self.url, {"duration_weeks": 8})
        self.assertEqual(res.data["count"], 1)
        self.assertEqual(res.data["results"][0]["duration_weeks"], 8)

    def test_company_filter(self):
        res = self.client.get(self.url, {"company": self.c1.id})
        self.assertEqual(res.data["count"], 1)
        self.assertEqual(res.data["results"][0]["company"]["id"], self.c1.id)


class PaginationTests(APITestCase):
    def test_pagination_limits_page_size(self):
        company = make_company()
        student = make_student()
        for i in range(25):
            make_offer(
                company, status=Offer.Status.PUBLISHED, title=f"Offer {i}"
            )
        self.client.force_authenticate(student)
        res = self.client.get(reverse("offer-list-create"))
        self.assertEqual(res.data["count"], 25)
        self.assertEqual(len(res.data["results"]), 20)  # DefaultPagination
        self.assertIsNotNone(res.data["next"])


class MineAndDetailVisibilityTests(APITestCase):
    def setUp(self):
        self.owner = make_company(email="owner@example.com")
        self.other = make_company(email="other@example.com")
        self.student = make_student()
        self.draft = make_offer(self.owner, status=Offer.Status.DRAFT)
        self.published = make_offer(self.owner, status=Offer.Status.PUBLISHED)

    def test_mine_returns_all_own_statuses(self):
        self.client.force_authenticate(self.owner)
        res = self.client.get(reverse("offer-mine"))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["count"], 2)

    def test_mine_forbidden_for_non_company(self):
        self.client.force_authenticate(self.student)
        res = self.client.get(reverse("offer-mine"))
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_published_detail_visible_to_any_user(self):
        self.client.force_authenticate(self.student)
        res = self.client.get(reverse("offer-detail", args=[self.published.id]))
        self.assertEqual(res.status_code, status.HTTP_200_OK)

    def test_draft_detail_not_visible_to_non_owner(self):
        self.client.force_authenticate(self.student)
        res = self.client.get(reverse("offer-detail", args=[self.draft.id]))
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_draft_detail_visible_to_owner(self):
        self.client.force_authenticate(self.owner)
        res = self.client.get(reverse("offer-detail", args=[self.draft.id]))
        self.assertEqual(res.status_code, status.HTTP_200_OK)

    def test_other_company_cannot_see_draft_detail(self):
        self.client.force_authenticate(self.other)
        res = self.client.get(reverse("offer-detail", args=[self.draft.id]))
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
