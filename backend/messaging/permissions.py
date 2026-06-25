"""Authorization for messaging."""

from rest_framework.permissions import BasePermission

from .models import MessageThread


class IsThreadParticipant(BasePermission):
    """Object-level: a party to the thread's internship (student/company/
    assigned teacher) or an admin may read and post."""

    message = "You are not a participant of this conversation."

    def has_object_permission(self, request, view, obj: MessageThread) -> bool:
        user = request.user
        if not (user and user.is_authenticated):
            return False
        internship = obj.internship
        return user.role == "admin" or user.id in (
            internship.student_id,
            internship.company_id,
            internship.teacher_id,
        )
