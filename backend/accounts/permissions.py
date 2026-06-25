"""Authorization for accounts endpoints."""

from rest_framework.permissions import BasePermission

from core.permissions import RoleRequired

from .models import SupervisionRequest


class IsTeacherOrAdmin(RoleRequired):
    """Teachers (to claim/release their students) and admins (to assign anyone)."""

    allowed_roles = ("teacher", "admin")


class IsStudentOrTeacher(RoleRequired):
    """Either party that can initiate a supervision request."""

    allowed_roles = ("student", "teacher")


class CanValidateSupervisionRequest(BasePermission):
    """Object-level: only the counterparty (the non-initiator) may accept/reject."""

    message = "Only the other party can respond to this request."

    def has_object_permission(self, request, view, obj: SupervisionRequest) -> bool:
        user = request.user
        if not (user and user.is_authenticated):
            return False
        if obj.initiated_by == SupervisionRequest.Initiator.STUDENT:
            return obj.teacher_id == user.id
        return obj.student_id == user.id


class CanCancelSupervisionRequest(BasePermission):
    """Object-level: only the initiator may cancel their pending request."""

    message = "Only the requester can cancel this request."

    def has_object_permission(self, request, view, obj: SupervisionRequest) -> bool:
        user = request.user
        if not (user and user.is_authenticated):
            return False
        if obj.initiated_by == SupervisionRequest.Initiator.STUDENT:
            return obj.student_id == user.id
        return obj.teacher_id == user.id
