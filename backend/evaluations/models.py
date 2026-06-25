from django.conf import settings
from django.db import models

from core.models import TimeStampedModel


class Evaluation(TimeStampedModel):
    """An evaluation of an internship by one party (SRS §7, EVAL-01..03).

    One per ``(internship, evaluator_type)``. Read-only once submitted.
    """

    class EvaluatorType(models.TextChoices):
        COMPANY = "company", "Company"
        TEACHER = "teacher", "Teacher"
        STUDENT = "student", "Student"

    internship = models.ForeignKey(
        "internships.Internship",
        on_delete=models.CASCADE,
        related_name="evaluations",
    )
    evaluator = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="evaluations",
    )
    evaluator_type = models.CharField(max_length=10, choices=EvaluatorType.choices)
    scores = models.JSONField(default=dict)
    comment = models.TextField(blank=True)
    total_score = models.FloatField(default=0)

    class Meta:
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["internship", "evaluator_type"],
                name="unique_evaluation_per_type",
            )
        ]
        indexes = [models.Index(fields=["internship", "evaluator_type"])]

    def __str__(self) -> str:
        return (
            f"Evaluation<internship {self.internship_id} "
            f"by {self.evaluator_type} ({self.total_score})>"
        )
