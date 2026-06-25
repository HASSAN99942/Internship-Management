"""Read queries for evaluations."""

from django.shortcuts import get_object_or_404

from .constants import CRITERIA_BY_TYPE
from .models import Evaluation
from .services import get_evaluation_summary


def list_internship_evaluations(internship):
    return internship.evaluations.select_related("evaluator").order_by(
        "evaluator_type"
    )


def get_evaluation(evaluation_id) -> Evaluation:
    return get_object_or_404(
        Evaluation.objects.select_related(
            "evaluator", "internship", "internship__student"
        ),
        pk=evaluation_id,
    )


def get_evaluations_payload(internship) -> dict:
    """Aggregate for the internship detail: criteria + evaluations + summary."""
    return {
        "criteria": {
            "company": CRITERIA_BY_TYPE["company"],
            "teacher": CRITERIA_BY_TYPE["teacher"],
            "student": CRITERIA_BY_TYPE["student"],
        },
        "evaluations": list_internship_evaluations(internship),
        "summary": get_evaluation_summary(internship),
    }
