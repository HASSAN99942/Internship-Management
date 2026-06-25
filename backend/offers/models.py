from django.conf import settings
from django.db import models

from core.models import TimeStampedModel


class Offer(TimeStampedModel):
    """An internship offer posted by a company (SRS §7, OFFER-01)."""

    class Status(models.TextChoices):
        DRAFT = "draft", "Draft"
        PUBLISHED = "published", "Published"
        CLOSED = "closed", "Closed"

    company = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="offers",
        limit_choices_to={"role": "company"},
    )
    title = models.CharField(max_length=255)
    description = models.TextField()
    skills = models.TextField(blank=True)
    location = models.CharField(max_length=255)
    duration_weeks = models.PositiveIntegerField()
    start_date = models.DateField()
    positions = models.PositiveIntegerField(default=1)
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.DRAFT
    )

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["status"]),
            models.Index(fields=["company"]),
        ]

    def __str__(self) -> str:
        return f"{self.title} ({self.status})"

    def is_open(self) -> bool:
        """Whether the offer is currently accepting interest (published)."""
        return self.status == self.Status.PUBLISHED
