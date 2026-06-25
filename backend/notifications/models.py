from django.conf import settings
from django.db import models

from core.models import TimeStampedModel


class Notification(TimeStampedModel):
    """An in-app notification for a single recipient (SRS §7, NOTIF-01).

    ``type`` is one of the module-level constants below; ``payload`` carries the
    related ids, a short human-readable ``message``, and a ``route`` the frontend
    navigates to when the notification is opened.
    """

    class Type(models.TextChoices):
        APPLICATION_RECEIVED = "application_received", "Application received"
        APPLICATION_ACCEPTED = "application_accepted", "Application accepted"
        APPLICATION_REJECTED = "application_rejected", "Application rejected"
        AGREEMENT_TO_VALIDATE = "agreement_to_validate", "Agreement to validate"
        INTERNSHIP_ACTIVATED = "internship_activated", "Internship activated"
        TASK_ASSIGNED = "task_assigned", "Task assigned"
        TASK_SUBMITTED = "task_submitted", "Task submitted"
        TASK_VALIDATED = "task_validated", "Task validated"
        TASK_CHANGES_REQUESTED = "task_changes_requested", "Task changes requested"
        REPORT_SUBMITTED = "report_submitted", "Report submitted"
        REPORT_VALIDATED = "report_validated", "Report validated"
        REPORT_CHANGES_REQUESTED = (
            "report_changes_requested",
            "Report changes requested",
        )
        NEW_MESSAGE = "new_message", "New message"
        EVALUATION_SUBMITTED = "evaluation_submitted", "Evaluation submitted"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notifications",
    )
    type = models.CharField(max_length=40, choices=Type.choices)
    payload = models.JSONField(default=dict, blank=True)
    is_read = models.BooleanField(default=False)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["user", "is_read"]),
            models.Index(fields=["user", "-created_at"]),
        ]

    def __str__(self) -> str:
        return f"Notification<{self.type} -> {self.user_id} (read={self.is_read})>"
