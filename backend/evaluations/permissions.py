"""Authorization for evaluations."""

from rest_framework.permissions import BasePermission

from internships.models import Internship
from .models import Evaluation


def _internship_of(obj) -> Internship:
    return obj if isinstance(obj, Internship) else obj.internship


class CanViewEvaluations(BasePermission):
    """Object-level: a party to the internship (student/company/teacher) or admin.

    Works for an Internship or an Evaluation instance.
    """

    message = "These evaluations are not available to you."

    def has_object_permission(self, request, view, obj) -> bool:
        user = request.user
        if not (user and user.is_authenticated):
            return False
        internship = _internship_of(obj)
        return user.role == "admin" or user.id in (
            internship.student_id,
            internship.company_id,
            internship.teacher_id,
        )


class CanSubmitEvaluation(BasePermission):
    """Object-level (Internship): the caller must be the matching party for the
    evaluator_type their role maps to. Admins cannot submit (no evaluator_type)."""

    message = "You cannot submit this type of evaluation."

    def has_object_permission(self, request, view, internship: Internship) -> bool:
        user = request.user
        if not (user and user.is_authenticated):
            return False
        if user.role == Evaluation.EvaluatorType.COMPANY:
            return internship.company_id == user.id
        if user.role == Evaluation.EvaluatorType.TEACHER:
            return internship.teacher_id == user.id
        if user.role == Evaluation.EvaluatorType.STUDENT:
            return internship.student_id == user.id
        return False
