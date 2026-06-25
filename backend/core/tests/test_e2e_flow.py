"""
End-to-end backend flow test.

Walks the full internship spine through the API in one test method:
  register → company posts offer → student applies →
  company accepts → teacher validates → task assigned/submitted/validated →
  report submitted/validated → messages exchanged →
  evaluations submitted.

State and notification counts are asserted at each step.
"""

import datetime

from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.services import register_user
from internships.models import Internship, Report, Task
from notifications.models import Notification

User = get_user_model()


class FullInternshipSpineTest(APITestCase):
    """
    Single test that exercises the complete happy path end-to-end.
    Each assertion block documents both the state change and the expected
    notification recipients so regressions are instantly visible.
    """

    def setUp(self):
        # Create users via services (avoids HTTP register overhead in setUp)
        self.teacher = register_user(
            email="e2e.teacher@example.com",
            password="Str0ngPass!23",
            role="teacher",
            first_name="E2E",
            last_name="Teacher",
            profile={"department": "CS", "title": "Prof"},
        )
        self.company = register_user(
            email="e2e.company@example.com",
            password="Str0ngPass!23",
            role="company",
            first_name="E2E",
            last_name="Company",
            profile={"company_name": "E2E Corp"},
        )
        self.student = register_user(
            email="e2e.student@example.com",
            password="Str0ngPass!23",
            role="student",
            first_name="E2E",
            last_name="Student",
            profile={"school": "ENSA", "program": "SE", "level": "M1"},
        )

        # Assign teacher to student
        profile = self.student.student_profile
        profile.assigned_teacher = self.teacher
        profile.save()
        # Refresh to clear profile cache so accept_application picks up teacher
        self.student = User.objects.get(id=self.student.id)

    # ---------------------------------------------------------------------- #

    def test_full_spine(self):
        student = self.student
        company = self.company
        teacher = self.teacher

        # ------------------------------------------------------------------ #
        # 1. Company creates and publishes an offer
        # ------------------------------------------------------------------ #
        self.client.force_authenticate(company)
        today = datetime.date.today()
        res = self.client.post(reverse("offer-list-create"), {
            "title": "Software Engineer Intern",
            "description": "Build great things.",
            "skills": "Python, Django",
            "location": "Remote",
            "duration_weeks": 12,
            "start_date": str(today + datetime.timedelta(weeks=4)),
            "positions": 2,
        }, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        offer_id = res.data["id"]

        res = self.client.post(reverse("offer-publish", args=[offer_id]))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["status"], "published")

        # ------------------------------------------------------------------ #
        # 2. Student applies
        # ------------------------------------------------------------------ #
        self.client.force_authenticate(student)
        res = self.client.post(
            reverse("offer-apply", args=[offer_id]),
            {"cover_message": "I would love to join your team."},
            format="multipart",
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        app_id = res.data["id"]

        # Company should have received an application_received notification
        self.assertEqual(
            Notification.objects.filter(
                user=company, type="application_received"
            ).count(),
            1,
            "Company should receive application_received notification on apply",
        )

        # ------------------------------------------------------------------ #
        # 3. Company accepts the application
        # ------------------------------------------------------------------ #
        self.client.force_authenticate(company)
        res = self.client.post(reverse("application-accept", args=[app_id]))
        self.assertEqual(res.status_code, status.HTTP_200_OK)

        # AcceptApplicationView returns ApplicationReadSerializer (not the
        # internship), so look up the internship by application FK.
        from applications.models import Application as AppModel
        app_obj = AppModel.objects.get(id=app_id)
        internship = app_obj.internship  # OneToOne reverse
        internship_id = internship.id
        self.assertEqual(internship.status, Internship.Status.PENDING_ACADEMIC_VALIDATION)
        self.assertEqual(internship.teacher, teacher)

        # Student gets application_accepted notification;
        # teacher gets agreement_to_validate notification
        self.assertEqual(
            Notification.objects.filter(user=student, type="application_accepted").count(),
            1,
            "Student should receive application_accepted notification",
        )
        self.assertEqual(
            Notification.objects.filter(user=teacher, type="agreement_to_validate").count(),
            1,
            "Teacher should receive agreement_to_validate notification",
        )

        # ------------------------------------------------------------------ #
        # 4. Teacher validates the agreement → internship becomes active
        # ------------------------------------------------------------------ #
        self.client.force_authenticate(teacher)
        res = self.client.post(reverse("internship-validate", args=[internship_id]))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["status"], Internship.Status.ACTIVE)

        # Student + company get internship_activated notifications
        self.assertEqual(
            Notification.objects.filter(
                user=student, type="internship_activated"
            ).count(),
            1,
            "Student should receive internship_activated notification",
        )
        self.assertEqual(
            Notification.objects.filter(
                user=company, type="internship_activated"
            ).count(),
            1,
            "Company should receive internship_activated notification",
        )

        # ------------------------------------------------------------------ #
        # 5. Company creates a task
        # ------------------------------------------------------------------ #
        self.client.force_authenticate(company)
        res = self.client.post(
            reverse("task-list-create", args=[internship_id]),
            {
                "title": "Build login API",
                "description": "Implement the /auth/login endpoint.",
                "due_date": str(today + datetime.timedelta(weeks=2)),
            },
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        task_id = res.data["id"]
        self.assertEqual(res.data["status"], Task.Status.OPEN)

        # Student gets task_assigned notification
        self.assertEqual(
            Notification.objects.filter(user=student, type="task_assigned").count(),
            1,
            "Student should receive task_assigned notification",
        )

        # ------------------------------------------------------------------ #
        # 6. Student submits the task
        # ------------------------------------------------------------------ #
        self.client.force_authenticate(student)
        res = self.client.post(
            reverse("task-submit", args=[task_id]),
            {"submission_note": "Done. PR #1 open for review."},
            format="multipart",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["status"], Task.Status.SUBMITTED)

        # Supervisors (company + teacher) get task_submitted notifications
        self.assertEqual(
            Notification.objects.filter(user=company, type="task_submitted").count(),
            1,
        )
        self.assertEqual(
            Notification.objects.filter(user=teacher, type="task_submitted").count(),
            1,
        )

        # ------------------------------------------------------------------ #
        # 7. Company validates the task
        # ------------------------------------------------------------------ #
        self.client.force_authenticate(company)
        res = self.client.post(reverse("task-validate", args=[task_id]))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["status"], Task.Status.VALIDATED)

        # Student gets task_validated notification
        self.assertEqual(
            Notification.objects.filter(user=student, type="task_validated").count(),
            1,
        )

        # ------------------------------------------------------------------ #
        # 8. Student submits a report
        # ------------------------------------------------------------------ #
        self.client.force_authenticate(student)
        res = self.client.post(
            reverse("report-list-create", args=[internship_id]),
            {
                "title": "Week 1 Report",
                "content": "Good week. Implemented the login API.",
                "period": "Week 1",
            },
            format="multipart",
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        report_id = res.data["id"]
        self.assertEqual(res.data["status"], Report.Status.SUBMITTED)

        # Supervisors get report_submitted notifications
        self.assertEqual(
            Notification.objects.filter(user=company, type="report_submitted").count(),
            1,
        )
        self.assertEqual(
            Notification.objects.filter(user=teacher, type="report_submitted").count(),
            1,
        )

        # ------------------------------------------------------------------ #
        # 9. Teacher validates the report
        # ------------------------------------------------------------------ #
        self.client.force_authenticate(teacher)
        res = self.client.post(reverse("report-validate", args=[report_id]))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["status"], Report.Status.VALIDATED)

        # Student gets report_validated notification
        self.assertEqual(
            Notification.objects.filter(user=student, type="report_validated").count(),
            1,
        )

        # ------------------------------------------------------------------ #
        # 10. Student + company exchange messages
        # ------------------------------------------------------------------ #
        from messaging.models import MessageThread

        thread = MessageThread.objects.get(internship_id=internship_id)

        self.client.force_authenticate(student)
        res = self.client.post(
            reverse("thread-messages", args=[thread.id]),
            {"body": "Hello from student!"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)

        # company + teacher get new_message notifications
        self.assertEqual(
            Notification.objects.filter(user=company, type="new_message").count(), 1
        )
        self.assertEqual(
            Notification.objects.filter(user=teacher, type="new_message").count(), 1
        )
        # sender does NOT get new_message for their own message
        self.assertEqual(
            Notification.objects.filter(user=student, type="new_message").count(), 0
        )

        self.client.force_authenticate(company)
        res = self.client.post(
            reverse("thread-messages", args=[thread.id]),
            {"body": "Hello from company!"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)

        # student gets a new_message notification now
        self.assertEqual(
            Notification.objects.filter(user=student, type="new_message").count(), 1
        )

        # ------------------------------------------------------------------ #
        # 11. Company submits evaluation
        # ------------------------------------------------------------------ #
        # Criteria keys + range come from evaluations/constants.py:
        # company/teacher: technical_skills, autonomy, communication,
        #                  professionalism, overall — scores 1..5
        COMPANY_SCORES = {
            "technical_skills": 4,
            "autonomy": 4,
            "communication": 5,
            "professionalism": 4,
            "overall": 4,
        }
        self.client.force_authenticate(company)
        res = self.client.post(
            reverse("evaluation-list-create", args=[internship_id]),
            {"scores": COMPANY_SCORES, "comment": "Great intern."},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data["evaluator_type"], "company")
        self.assertIsNotNone(res.data["total_score"])

        # ------------------------------------------------------------------ #
        # 12. Teacher submits evaluation
        # ------------------------------------------------------------------ #
        TEACHER_SCORES = {
            "technical_skills": 5,
            "autonomy": 4,
            "communication": 4,
            "professionalism": 5,
            "overall": 5,
        }
        self.client.force_authenticate(teacher)
        res = self.client.post(
            reverse("evaluation-list-create", args=[internship_id]),
            {"scores": TEACHER_SCORES, "comment": "Excellent progress."},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data["evaluator_type"], "teacher")

        # ------------------------------------------------------------------ #
        # 13. Student views evaluation summary
        # ------------------------------------------------------------------ #
        self.client.force_authenticate(student)
        res = self.client.get(reverse("evaluation-list-create", args=[internship_id]))
        self.assertEqual(res.status_code, status.HTTP_200_OK)

        # ------------------------------------------------------------------ #
        # Final sanity checks
        # ------------------------------------------------------------------ #
        internship.refresh_from_db()
        # Two evaluations recorded
        self.assertEqual(internship.evaluations.count(), 2)
        # One validated task
        self.assertEqual(
            internship.tasks.filter(status=Task.Status.VALIDATED).count(), 1
        )
        # One validated report
        self.assertEqual(
            internship.reports.filter(status=Report.Status.VALIDATED).count(), 1
        )
