from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.models import SupervisionRequest, User
from accounts.services import register_user

PASSWORD = "Str0ngPass!23"
_n = {"i": 0}


def _email(prefix):
    _n["i"] += 1
    return f"{prefix}{_n['i']}@example.com"


def make_student():
    return register_user(
        email=_email("stu"),
        password=PASSWORD,
        role="student",
        profile={"school": "ENSA", "program": "SE", "level": "M1"},
    )


def make_teacher():
    return register_user(
        email=_email("teach"),
        password=PASSWORD,
        role="teacher",
        profile={"department": "CS"},
    )


class SupervisionRequestTests(APITestCase):
    def setUp(self):
        self.student = make_student()
        self.teacher = make_teacher()
        self.other_teacher = make_teacher()
        self.other_student = make_student()
        self.list_create_url = reverse("supervision-request-list-create")

    # --- creation -------------------------------------------------------- #
    def test_student_requests_teacher(self):
        self.client.force_authenticate(self.student)
        res = self.client.post(
            self.list_create_url, {"target_id": self.teacher.id}, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data["initiated_by"], "student")
        self.assertEqual(res.data["status"], "pending")

    def test_teacher_requests_student(self):
        self.client.force_authenticate(self.teacher)
        res = self.client.post(
            self.list_create_url, {"target_id": self.student.id}, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data["initiated_by"], "teacher")

    def test_company_cannot_request(self):
        company = register_user(
            email=_email("co"),
            password=PASSWORD,
            role="company",
            profile={"company_name": "Acme"},
        )
        self.client.force_authenticate(company)
        res = self.client.post(
            self.list_create_url, {"target_id": self.teacher.id}, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_duplicate_pending_blocked(self):
        self.client.force_authenticate(self.student)
        self.client.post(
            self.list_create_url, {"target_id": self.teacher.id}, format="json"
        )
        res = self.client.post(
            self.list_create_url, {"target_id": self.other_teacher.id}, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    # --- accept (counterparty validates) -------------------------------- #
    def test_teacher_accepts_student_request_sets_supervisor(self):
        self.client.force_authenticate(self.student)
        req_id = self.client.post(
            self.list_create_url, {"target_id": self.teacher.id}, format="json"
        ).data["id"]

        self.client.force_authenticate(self.teacher)
        res = self.client.post(
            reverse("supervision-request-accept", args=[req_id])
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["status"], "accepted")
        self.student.refresh_from_db()
        self.assertEqual(self.student.student_profile.assigned_teacher_id, self.teacher.id)

    def test_student_accepts_teacher_request(self):
        self.client.force_authenticate(self.teacher)
        req_id = self.client.post(
            self.list_create_url, {"target_id": self.student.id}, format="json"
        ).data["id"]

        self.client.force_authenticate(self.student)
        res = self.client.post(
            reverse("supervision-request-accept", args=[req_id])
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.student.refresh_from_db()
        self.assertEqual(
            self.student.student_profile.assigned_teacher_id, self.teacher.id
        )

    def test_initiator_cannot_validate_own_request(self):
        # Student initiated -> student cannot accept; only the teacher can.
        self.client.force_authenticate(self.student)
        req_id = self.client.post(
            self.list_create_url, {"target_id": self.teacher.id}, format="json"
        ).data["id"]
        res = self.client.post(
            reverse("supervision-request-accept", args=[req_id])
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_uninvolved_teacher_cannot_validate(self):
        self.client.force_authenticate(self.student)
        req_id = self.client.post(
            self.list_create_url, {"target_id": self.teacher.id}, format="json"
        ).data["id"]
        self.client.force_authenticate(self.other_teacher)
        res = self.client.post(
            reverse("supervision-request-accept", args=[req_id])
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    # --- reject / cancel ------------------------------------------------- #
    def test_counterparty_rejects(self):
        self.client.force_authenticate(self.student)
        req_id = self.client.post(
            self.list_create_url, {"target_id": self.teacher.id}, format="json"
        ).data["id"]
        self.client.force_authenticate(self.teacher)
        res = self.client.post(
            reverse("supervision-request-reject", args=[req_id])
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["status"], "rejected")
        self.student.refresh_from_db()
        self.assertIsNone(self.student.student_profile.assigned_teacher_id)

    def test_initiator_cancels(self):
        self.client.force_authenticate(self.student)
        req_id = self.client.post(
            self.list_create_url, {"target_id": self.teacher.id}, format="json"
        ).data["id"]
        res = self.client.post(
            reverse("supervision-request-cancel", args=[req_id])
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["status"], "cancelled")

    def test_counterparty_cannot_cancel(self):
        # Student initiated -> teacher (counterparty) cannot cancel.
        self.client.force_authenticate(self.student)
        req_id = self.client.post(
            self.list_create_url, {"target_id": self.teacher.id}, format="json"
        ).data["id"]
        self.client.force_authenticate(self.teacher)
        res = self.client.post(
            reverse("supervision-request-cancel", args=[req_id])
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_cannot_request_when_already_supervised(self):
        # Accept once, then a fresh request should be rejected.
        self.client.force_authenticate(self.student)
        req_id = self.client.post(
            self.list_create_url, {"target_id": self.teacher.id}, format="json"
        ).data["id"]
        self.client.force_authenticate(self.teacher)
        self.client.post(reverse("supervision-request-accept", args=[req_id]))

        self.client.force_authenticate(self.student)
        res = self.client.post(
            self.list_create_url, {"target_id": self.other_teacher.id}, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    # --- list scoping ---------------------------------------------------- #
    def test_list_is_role_scoped(self):
        self.client.force_authenticate(self.student)
        self.client.post(
            self.list_create_url, {"target_id": self.teacher.id}, format="json"
        )
        # the involved teacher sees it
        self.client.force_authenticate(self.teacher)
        self.assertEqual(len(self.client.get(self.list_create_url).data), 1)
        # an uninvolved teacher does not
        self.client.force_authenticate(self.other_teacher)
        self.assertEqual(len(self.client.get(self.list_create_url).data), 0)


class RegistrationNoLongerSetsSupervisor(APITestCase):
    def test_assigned_teacher_ignored_at_signup(self):
        teacher = make_teacher()
        res = self.client.post(
            reverse("register"),
            {
                "email": "fresh@example.com",
                "password": PASSWORD,
                "role": "student",
                "profile": {
                    "school": "ENSA",
                    "program": "SE",
                    "level": "M1",
                    "assigned_teacher": teacher.id,
                },
            },
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        user = User.objects.get(email="fresh@example.com")
        # The signup picker was removed; supervisor must not be set at signup.
        self.assertIsNone(user.student_profile.assigned_teacher_id)
        self.assertFalse(
            SupervisionRequest.objects.filter(student=user).exists()
        )
