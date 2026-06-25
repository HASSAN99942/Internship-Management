from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from applications.models import Application
from applications.services import accept_application
from applications.tests.utils import (
    make_company,
    make_published_offer,
    make_student,
    make_teacher,
)
from evaluations.models import Evaluation
from internships.models import Internship
from internships.services import validate_internship

User = get_user_model()

GOOD_PRO_SCORES = {
    "technical_skills": 8,
    "autonomy": 9,
    "communication": 7,
    "professionalism": 8,
    "overall": 8,
}
GOOD_STUDENT_SCORES = {"supervision": 9, "learning": 8, "environment": 7}


def build_active_internship():
    """Active internship with student/company/assigned-teacher. Returns the 4-tuple."""
    company = make_company()
    student = make_student()
    teacher = make_teacher()
    profile = student.student_profile
    profile.assigned_teacher = teacher
    profile.save()
    offer = make_published_offer(company, positions=3)
    Application.objects.create(offer=offer, student=student, cover_message="Hi")
    application = Application.objects.get(offer=offer, student=student)
    internship = accept_application(application=application)
    validate_internship(internship=internship, by_user=teacher)
    internship.refresh_from_db()
    return internship, student, company, teacher


class EvaluationTests(APITestCase):
    def setUp(self):
        self.internship, self.student, self.company, self.teacher = (
            build_active_internship()
        )
        self.outsider = make_company()
        self.url = reverse(
            "evaluation-list-create", args=[self.internship.id]
        )

    def _post(self, scores, comment="Good work"):
        return self.client.post(
            self.url, {"scores": scores, "comment": comment}, format="json"
        )

    # --- submission per role -------------------------------------------- #
    def test_company_submits_company_evaluation(self):
        self.client.force_authenticate(self.company)
        res = self._post(GOOD_PRO_SCORES)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data["evaluator_type"], "company")
        self.assertEqual(res.data["total_score"], 8.0)

    def test_teacher_submits_teacher_evaluation(self):
        self.client.force_authenticate(self.teacher)
        res = self._post(GOOD_PRO_SCORES)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data["evaluator_type"], "teacher")

    def test_student_submits_student_rating(self):
        self.client.force_authenticate(self.student)
        res = self._post(GOOD_STUDENT_SCORES)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data["evaluator_type"], "student")
        self.assertAlmostEqual(res.data["total_score"], round((9 + 8 + 7) / 3, 2))

    # --- authorization --------------------------------------------------- #
    def test_outsider_cannot_submit(self):
        self.client.force_authenticate(self.outsider)
        res = self._post(GOOD_PRO_SCORES)
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_cannot_submit(self):
        admin = User.objects.create_superuser(
            email="admin@example.com", password="Str0ngPass!23"
        )
        self.client.force_authenticate(admin)
        res = self._post(GOOD_PRO_SCORES)
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

    # --- uniqueness ------------------------------------------------------ #
    def test_duplicate_type_rejected(self):
        self.client.force_authenticate(self.company)
        self.assertEqual(self._post(GOOD_PRO_SCORES).status_code, 201)
        res = self._post(GOOD_PRO_SCORES)
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(
            Evaluation.objects.filter(
                internship=self.internship, evaluator_type="company"
            ).count(),
            1,
        )

    # --- status gate ----------------------------------------------------- #
    def test_cannot_submit_when_not_active_or_completed(self):
        # Build a fresh internship left in pending_academic_validation.
        company = make_company()
        student = make_student()
        teacher = make_teacher()
        sp = student.student_profile
        sp.assigned_teacher = teacher
        sp.save()
        offer = make_published_offer(company, positions=2)
        Application.objects.create(offer=offer, student=student, cover_message="Hi")
        application = Application.objects.get(offer=offer, student=student)
        pending = accept_application(application=application)
        self.assertEqual(pending.status, "pending_academic_validation")

        url = reverse("evaluation-list-create", args=[pending.id])
        self.client.force_authenticate(company)
        res = self.client.post(
            url, {"scores": GOOD_PRO_SCORES, "comment": ""}, format="json"
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_submit_allowed_when_completed(self):
        self.internship.status = Internship.Status.COMPLETED
        self.internship.save(update_fields=["status"])
        self.client.force_authenticate(self.company)
        self.assertEqual(self._post(GOOD_PRO_SCORES).status_code, 201)

    # --- score validation ------------------------------------------------ #
    def test_out_of_range_score_rejected(self):
        self.client.force_authenticate(self.company)
        bad = {**GOOD_PRO_SCORES, "overall": 11}
        self.assertEqual(self._post(bad).status_code, 400)

    def test_unknown_criterion_rejected(self):
        self.client.force_authenticate(self.company)
        bad = {**GOOD_PRO_SCORES, "charisma": 5}
        self.assertEqual(self._post(bad).status_code, 400)

    def test_missing_criterion_rejected(self):
        self.client.force_authenticate(self.company)
        bad = dict(GOOD_PRO_SCORES)
        bad.pop("overall")
        self.assertEqual(self._post(bad).status_code, 400)

    # --- summary --------------------------------------------------------- #
    def test_summary_combines_company_and_teacher(self):
        # GOOD_PRO_SCORES = {8,9,7,8,8} -> total 8.0
        # teacher variant overall=6 -> {8,9,7,8,6} -> total 7.6
        self.client.force_authenticate(self.company)
        self._post(GOOD_PRO_SCORES)
        self.client.force_authenticate(self.teacher)
        self._post({**GOOD_PRO_SCORES, "overall": 6})

        self.client.force_authenticate(self.student)
        data = self.client.get(self.url).data
        self.assertIsNotNone(data["summary"]["company"])
        self.assertIsNotNone(data["summary"]["teacher"])
        self.assertAlmostEqual(data["summary"]["combined"], round((8.0 + 7.6) / 2, 2))
        self.assertIn("company", data["criteria"])

    # --- notifications --------------------------------------------------- #
    def test_company_submission_notifies_student(self):
        from notifications.models import Notification

        self.client.force_authenticate(self.company)
        self._post(GOOD_PRO_SCORES)
        self.assertTrue(
            Notification.objects.filter(
                user=self.student,
                type=Notification.Type.EVALUATION_SUBMITTED,
            ).exists()
        )

    def test_teacher_submission_notifies_student(self):
        from notifications.models import Notification

        self.client.force_authenticate(self.teacher)
        self._post(GOOD_PRO_SCORES)
        self.assertTrue(
            Notification.objects.filter(
                user=self.student,
                type=Notification.Type.EVALUATION_SUBMITTED,
            ).exists()
        )

    def test_student_self_rating_does_not_notify(self):
        from notifications.models import Notification

        self.client.force_authenticate(self.student)
        self._post(GOOD_STUDENT_SCORES)
        self.assertFalse(
            Notification.objects.filter(
                user=self.student,
                type=Notification.Type.EVALUATION_SUBMITTED,
            ).exists()
        )

    # --- read scoping ---------------------------------------------------- #
    def test_read_restricted_to_parties(self):
        self.client.force_authenticate(self.student)
        self.assertEqual(self.client.get(self.url).status_code, 200)
        self.client.force_authenticate(self.outsider)
        self.assertEqual(
            self.client.get(self.url).status_code, status.HTTP_403_FORBIDDEN
        )
