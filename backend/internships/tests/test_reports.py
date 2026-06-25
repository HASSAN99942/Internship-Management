from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from .utils import make_active_internship, make_pending_internship, make_student


class ReportTests(APITestCase):
    def setUp(self):
        self.internship, self.student, self.company, self.teacher = (
            make_active_internship()
        )
        self.outsider = make_student()
        self.list_url = reverse("report-list-create", args=[self.internship.id])

    def _submit_report(self, by_user=None):
        self.client.force_authenticate(by_user or self.student)
        return self.client.post(
            self.list_url,
            {"title": "Week 1", "content": "Did things", "period": "Week 1"},
            format="json",
        )

    def test_student_submits_report(self):
        res = self._submit_report(self.student)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data["status"], "submitted")
        self.assertEqual(res.data["student"]["id"], self.student.id)

    def test_non_student_cannot_submit_report(self):
        self.client.force_authenticate(self.company)
        res = self.client.post(
            self.list_url,
            {"title": "X", "content": "Y", "period": "W1"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_cannot_submit_on_non_active_internship(self):
        pending, student, _company, _teacher = make_pending_internship()
        url = reverse("report-list-create", args=[pending.id])
        self.client.force_authenticate(student)
        res = self.client.post(
            url, {"title": "X", "content": "Y", "period": "W1"}, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_supervisor_validates_report(self):
        report_id = self._submit_report().data["id"]
        self.client.force_authenticate(self.company)
        res = self.client.post(reverse("report-validate", args=[report_id]))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["status"], "validated")

    def test_supervisor_requests_changes_with_feedback(self):
        report_id = self._submit_report().data["id"]
        self.client.force_authenticate(self.teacher)
        res = self.client.post(
            reverse("report-request-changes", args=[report_id]),
            {"feedback": "Add more detail"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["status"], "changes_requested")
        self.assertEqual(res.data["feedback"], "Add more detail")

    def test_request_changes_requires_feedback(self):
        report_id = self._submit_report().data["id"]
        self.client.force_authenticate(self.company)
        res = self.client.post(
            reverse("report-request-changes", args=[report_id]), {}, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_read_restricted_to_parties(self):
        self._submit_report()
        self.client.force_authenticate(self.teacher)
        self.assertEqual(self.client.get(self.list_url).status_code, 200)
        self.client.force_authenticate(self.outsider)
        self.assertEqual(
            self.client.get(self.list_url).status_code, status.HTTP_403_FORBIDDEN
        )
