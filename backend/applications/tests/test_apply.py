from django.core.files.uploadedfile import SimpleUploadedFile
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from applications.models import Application
from applications.services import accept_application
from offers.services import close_offer

from .utils import make_company, make_draft_offer, make_published_offer, make_student


class ApplyTests(APITestCase):
    def setUp(self):
        self.company = make_company()
        self.student = make_student()
        self.offer = make_published_offer(self.company)
        self.url = reverse("offer-apply", args=[self.offer.id])

    def test_student_applies_success(self):
        self.client.force_authenticate(self.student)
        res = self.client.post(
            self.url, {"cover_message": "Hi"}, format="multipart"
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Application.objects.count(), 1)
        app = Application.objects.get()
        self.assertEqual(app.status, "pending")
        self.assertEqual(app.student, self.student)

    def test_apply_with_valid_cv(self):
        self.client.force_authenticate(self.student)
        cv = SimpleUploadedFile(
            "cv.pdf", b"%PDF-1.4 test", content_type="application/pdf"
        )
        res = self.client.post(
            self.url, {"cover_message": "Hi", "cv_file": cv}, format="multipart"
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertTrue(Application.objects.get().cv_file)

    def test_cv_invalid_extension_rejected(self):
        self.client.force_authenticate(self.student)
        bad = SimpleUploadedFile(
            "cv.exe", b"x", content_type="application/octet-stream"
        )
        res = self.client.post(
            self.url, {"cover_message": "Hi", "cv_file": bad}, format="multipart"
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(Application.objects.count(), 0)

    def test_duplicate_application_blocked(self):
        self.client.force_authenticate(self.student)
        self.client.post(self.url, {"cover_message": "Hi"}, format="multipart")
        res = self.client.post(
            self.url, {"cover_message": "Again"}, format="multipart"
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(Application.objects.count(), 1)

    def test_cannot_apply_to_closed_offer(self):
        close_offer(self.offer)
        self.client.force_authenticate(self.student)
        res = self.client.post(
            self.url, {"cover_message": "Hi"}, format="multipart"
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_cannot_apply_to_draft_offer(self):
        draft = make_draft_offer(self.company)
        url = reverse("offer-apply", args=[draft.id])
        self.client.force_authenticate(self.student)
        res = self.client.post(url, {"cover_message": "Hi"}, format="multipart")
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_cannot_apply_to_filled_offer(self):
        # positions=1; accepting the first applicant fills the offer.
        first = make_student()
        self.client.force_authenticate(first)
        self.client.post(self.url, {"cover_message": "Hi"}, format="multipart")
        accept_application(application=Application.objects.get(student=first))

        self.client.force_authenticate(self.student)
        res = self.client.post(
            self.url, {"cover_message": "Me too"}, format="multipart"
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_non_student_forbidden(self):
        self.client.force_authenticate(self.company)
        res = self.client.post(
            self.url, {"cover_message": "Hi"}, format="multipart"
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
