from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from internships.models import Task

from .utils import make_active_internship, make_pending_internship, make_student


class TaskTests(APITestCase):
    def setUp(self):
        self.internship, self.student, self.company, self.teacher = (
            make_active_internship()
        )
        self.outsider = make_student()
        self.list_url = reverse("task-list-create", args=[self.internship.id])

    def _create_task(self, by_user=None):
        self.client.force_authenticate(by_user or self.company)
        res = self.client.post(
            self.list_url, {"title": "Build API", "description": "d"}, format="json"
        )
        return res

    # --- creation -------------------------------------------------------- #
    def test_company_creates_task(self):
        res = self._create_task(self.company)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data["status"], "open")
        self.assertEqual(res.data["created_by"]["id"], self.company.id)

    def test_teacher_creates_task(self):
        res = self._create_task(self.teacher)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)

    def test_student_cannot_create_task(self):
        self.client.force_authenticate(self.student)
        res = self.client.post(self.list_url, {"title": "X"}, format="json")
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_outsider_cannot_create_task(self):
        self.client.force_authenticate(self.outsider)
        res = self.client.post(self.list_url, {"title": "X"}, format="json")
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_cannot_create_on_non_active_internship(self):
        pending, _student, company, _teacher = make_pending_internship()
        url = reverse("task-list-create", args=[pending.id])
        self.client.force_authenticate(company)
        res = self.client.post(url, {"title": "X"}, format="json")
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    # --- submission ------------------------------------------------------ #
    def test_student_submits_and_resubmits(self):
        task_id = self._create_task(self.company).data["id"]

        self.client.force_authenticate(self.student)
        res = self.client.post(
            reverse("task-submit", args=[task_id]),
            {"submission_note": "done"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["status"], "submitted")

        # supervisor returns it for changes, student resubmits
        self.client.force_authenticate(self.company)
        self.client.post(reverse("task-request-changes", args=[task_id]))
        self.client.force_authenticate(self.student)
        res = self.client.post(
            reverse("task-submit", args=[task_id]),
            {"submission_note": "fixed"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["status"], "submitted")

    def test_non_student_cannot_submit(self):
        task_id = self._create_task(self.company).data["id"]
        self.client.force_authenticate(self.company)
        res = self.client.post(reverse("task-submit", args=[task_id]))
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    # --- validation / request changes ----------------------------------- #
    def test_validate_submitted_task(self):
        task_id = self._create_task(self.company).data["id"]
        self.client.force_authenticate(self.student)
        self.client.post(
            reverse("task-submit", args=[task_id]),
            {"submission_note": "done"},
            format="json",
        )
        self.client.force_authenticate(self.teacher)
        res = self.client.post(reverse("task-validate", args=[task_id]))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["status"], "validated")

    def test_cannot_validate_open_task(self):
        task_id = self._create_task(self.company).data["id"]
        self.client.force_authenticate(self.company)
        res = self.client.post(reverse("task-validate", args=[task_id]))
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_cannot_submit_validated_task(self):
        task_id = self._create_task(self.company).data["id"]
        self.client.force_authenticate(self.student)
        self.client.post(
            reverse("task-submit", args=[task_id]),
            {"submission_note": "done"},
            format="json",
        )
        self.client.force_authenticate(self.company)
        self.client.post(reverse("task-validate", args=[task_id]))
        self.client.force_authenticate(self.student)
        res = self.client.post(reverse("task-submit", args=[task_id]))
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    # --- read scoping ---------------------------------------------------- #
    def test_read_restricted_to_parties(self):
        self._create_task(self.company)
        self.client.force_authenticate(self.student)
        self.assertEqual(self.client.get(self.list_url).status_code, 200)

        self.client.force_authenticate(self.outsider)
        self.assertEqual(
            self.client.get(self.list_url).status_code, status.HTTP_403_FORBIDDEN
        )

    def test_task_detail_restricted_to_parties(self):
        task_id = self._create_task(self.company).data["id"]
        url = reverse("task-detail", args=[task_id])
        self.client.force_authenticate(self.teacher)
        self.assertEqual(self.client.get(url).status_code, 200)
        self.client.force_authenticate(self.outsider)
        self.assertEqual(self.client.get(url).status_code, status.HTTP_403_FORBIDDEN)

    def test_task_count_in_db(self):
        self._create_task(self.company)
        self.assertEqual(Task.objects.filter(internship=self.internship).count(), 1)
