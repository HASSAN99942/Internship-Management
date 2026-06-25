from django.conf import settings
from django.db import models

from core.models import TimeStampedModel


class Internship(TimeStampedModel):
    """Internship agreement (convention) created when an application is accepted.

    Tasks/Reports (Phase 4) are intentionally not modelled yet (SRS §7).
    """

    class Status(models.TextChoices):
        PENDING_ACADEMIC_VALIDATION = (
            "pending_academic_validation",
            "Pending academic validation",
        )
        ACTIVE = "active", "Active"
        COMPLETED = "completed", "Completed"
        CANCELLED = "cancelled", "Cancelled"

    application = models.OneToOneField(
        "applications.Application",
        on_delete=models.CASCADE,
        related_name="internship",
    )
    student = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="internships_as_student",
        limit_choices_to={"role": "student"},
    )
    company = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="internships_as_company",
        limit_choices_to={"role": "company"},
    )
    teacher = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="internships_as_teacher",
        limit_choices_to={"role": "teacher"},
    )
    status = models.CharField(
        max_length=32,
        choices=Status.choices,
        default=Status.PENDING_ACADEMIC_VALIDATION,
    )
    start_date = models.DateField()
    end_date = models.DateField()

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["status"]),
            models.Index(fields=["student"]),
            models.Index(fields=["company"]),
            models.Index(fields=["teacher"]),
        ]

    def __str__(self) -> str:
        return f"Internship<app {self.application_id} ({self.status})>"


class Task(TimeStampedModel):
    """An assignable task within an internship (SRS §7, MON-02..04)."""

    class Status(models.TextChoices):
        OPEN = "open", "Open"
        SUBMITTED = "submitted", "Submitted"
        VALIDATED = "validated", "Validated"
        CHANGES_REQUESTED = "changes_requested", "Changes requested"

    internship = models.ForeignKey(
        Internship, on_delete=models.CASCADE, related_name="tasks"
    )
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name="created_tasks",
    )
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    due_date = models.DateField(null=True, blank=True)
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.OPEN
    )
    submission_note = models.TextField(blank=True)
    submission_file = models.FileField(
        upload_to="internships/tasks/", blank=True, null=True
    )

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["internship", "status"])]

    def __str__(self) -> str:
        return f"Task<{self.title} ({self.status})>"


class Report(TimeStampedModel):
    """A periodic report submitted by the student (SRS §7, MON-05..06)."""

    class Status(models.TextChoices):
        SUBMITTED = "submitted", "Submitted"
        VALIDATED = "validated", "Validated"
        CHANGES_REQUESTED = "changes_requested", "Changes requested"

    internship = models.ForeignKey(
        Internship, on_delete=models.CASCADE, related_name="reports"
    )
    student = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="reports",
        limit_choices_to={"role": "student"},
    )
    title = models.CharField(max_length=255)
    content = models.TextField()
    file = models.FileField(upload_to="internships/reports/", blank=True, null=True)
    period = models.CharField(max_length=100)
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.SUBMITTED
    )
    feedback = models.TextField(blank=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["internship", "status"])]

    def __str__(self) -> str:
        return f"Report<{self.title} ({self.status})>"
