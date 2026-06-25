from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from .utils import make_active_internship, make_student


class DashboardTests(APITestCase):
    def setUp(self):
        self.internship, self.student, self.company, self.teacher = (
            make_active_internship()
        )
        self.outsider = make_student()
        self.url = reverse("internship-detail", args=[self.internship.id])

    def _create_task(self):
        self.client.force_authenticate(self.company)
        return self.client.post(
            reverse("task-list-create", args=[self.internship.id]),
            {"title": "T", "description": "d"},
            format="json",
        ).data["id"]

    def _submit_report(self):
        self.client.force_authenticate(self.student)
        return self.client.post(
            reverse("report-list-create", args=[self.internship.id]),
            {"title": "R", "content": "c", "period": "W1"},
            format="json",
        ).data["id"]

    def test_dashboard_shape_and_parties(self):
        self.client.force_authenticate(self.student)
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn("internship", res.data)
        self.assertIn("tasks", res.data)
        self.assertIn("reports", res.data)
        self.assertIn("progress", res.data)
        self.assertEqual(res.data["internship"]["student"]["id"], self.student.id)
        self.assertEqual(res.data["internship"]["company"]["id"], self.company.id)

    def test_progress_numbers(self):
        # Two tasks, one validated.
        t1 = self._create_task()
        self._create_task()
        self.client.force_authenticate(self.student)
        self.client.post(
            reverse("task-submit", args=[t1]), {"submission_note": "x"}, format="json"
        )
        self.client.force_authenticate(self.company)
        self.client.post(reverse("task-validate", args=[t1]))

        # Two reports, one validated.
        r1 = self._submit_report()
        self._submit_report()
        self.client.force_authenticate(self.company)
        self.client.post(reverse("report-validate", args=[r1]))

        self.client.force_authenticate(self.teacher)
        progress = self.client.get(self.url).data["progress"]
        self.assertEqual(progress["tasks_total"], 2)
        self.assertEqual(progress["tasks_validated"], 1)
        self.assertEqual(progress["tasks_validated_pct"], 50)
        self.assertEqual(progress["reports_total"], 2)
        self.assertEqual(progress["reports_validated"], 1)
        self.assertEqual(progress["reports_validated_pct"], 50)

    def test_dashboard_restricted_to_parties(self):
        self.client.force_authenticate(self.outsider)
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
