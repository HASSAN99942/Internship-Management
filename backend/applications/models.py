from django.conf import settings
from django.db import models

from core.models import TimeStampedModel


class Application(TimeStampedModel):
    """A student's application to a published offer (SRS §7, APP-01..03)."""

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        ACCEPTED = "accepted", "Accepted"
        REJECTED = "rejected", "Rejected"
        WITHDRAWN = "withdrawn", "Withdrawn"

    offer = models.ForeignKey(
        "offers.Offer",
        on_delete=models.CASCADE,
        related_name="applications",
    )
    student = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="applications",
        limit_choices_to={"role": "student"},
    )
    cover_message = models.TextField()
    cv_file = models.FileField(upload_to="applications/cv/", blank=True, null=True)
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.PENDING
    )
    decided_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["offer", "student"], name="unique_application_per_offer"
            )
        ]
        indexes = [
            models.Index(fields=["status"]),
            models.Index(fields=["student"]),
        ]

    def __str__(self) -> str:
        return f"Application<{self.student_id} -> offer {self.offer_id} ({self.status})>"

    @property
    def is_pending(self) -> bool:
        return self.status == self.Status.PENDING
