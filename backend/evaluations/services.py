"""Business logic for evaluations — the only place that writes this data."""

from django.db import IntegrityError, transaction
from rest_framework.exceptions import ValidationError

from internships.models import Internship

from notifications import events

from .models import Evaluation


def _compute_total(scores: dict) -> float:
    if not scores:
        return 0.0
    return round(sum(scores.values()) / len(scores), 2)


@transaction.atomic
def submit_evaluation(
    *,
    internship: Internship,
    evaluator,
    evaluator_type: str,
    scores: dict,
    comment: str = "",
) -> Evaluation:
    """Create an evaluation. Party/role matching is enforced by the view's
    permission; here we enforce status, uniqueness, and compute the total."""
    if internship.status not in (
        Internship.Status.ACTIVE,
        Internship.Status.COMPLETED,
    ):
        raise ValidationError(
            "Evaluations are only available once the internship is active."
        )
    try:
        evaluation = Evaluation.objects.create(
            internship=internship,
            evaluator=evaluator,
            evaluator_type=evaluator_type,
            scores=scores,
            comment=comment or "",
            total_score=_compute_total(scores),
        )
    except IntegrityError:
        raise ValidationError(
            "An evaluation of this type has already been submitted."
        )
    events.notify_evaluation_submitted(evaluation)
    return evaluation


def get_evaluation_summary(internship: Internship) -> dict:
    """Per-type totals plus a combined figure (company + teacher mean).

    The student's self-rating is reported separately, not folded into the
    combined score (it rates the internship, not the student).
    """
    by_type = {
        e.evaluator_type: e
        for e in internship.evaluations.all()
    }

    def entry(evaluation):
        if evaluation is None:
            return None
        return {
            "total_score": evaluation.total_score,
            "scores": evaluation.scores,
            "comment": evaluation.comment,
        }

    company = by_type.get(Evaluation.EvaluatorType.COMPANY)
    teacher = by_type.get(Evaluation.EvaluatorType.TEACHER)
    student = by_type.get(Evaluation.EvaluatorType.STUDENT)

    professional_totals = [
        e.total_score for e in (company, teacher) if e is not None
    ]
    combined = (
        round(sum(professional_totals) / len(professional_totals), 2)
        if professional_totals
        else None
    )

    return {
        "company": entry(company),
        "teacher": entry(teacher),
        "student": entry(student),
        "combined": combined,
    }
