"""Authorization for internships, tasks, and reports."""

from rest_framework.permissions import BasePermission

from .models import Internship


def _internship_of(obj) -> Internship:
    """Resolve the internship for an Internship, Task, or Report instance."""
    return obj if isinstance(obj, Internship) else obj.internship


def _is_supervisor(user, internship: Internship) -> bool:
    return (
        user.role == "admin"
        or internship.company_id == user.id
        or (internship.teacher_id is not None and internship.teacher_id == user.id)
    )


class CanViewInternship(BasePermission):
    """Object-level: any party to the internship (student/company/teacher) or admin.

    Any teacher may also view a pending-validation internship that has no assigned
    teacher yet, so they can pick it up and validate it.
    """

    message = "This internship is not available."

    def has_object_permission(self, request, view, obj: Internship) -> bool:
        user = request.user
        if not (user and user.is_authenticated):
            return False
        if user.role == "admin":
            return True
        if user.id in (obj.student_id, obj.company_id, obj.teacher_id):
            return True
        # Any teacher can view an unassigned pending agreement.
        return (
            user.role == "teacher"
            and obj.teacher_id is None
            and obj.status == Internship.Status.PENDING_ACADEMIC_VALIDATION
        )


class CanValidateInternship(BasePermission):
    """Object-level: the assigned teacher, any teacher if unassigned, or an admin."""

    message = "Only the assigned teacher or an admin can validate this agreement."

    def has_object_permission(self, request, view, obj: Internship) -> bool:
        user = request.user
        if not (user and user.is_authenticated):
            return False
        if user.role == "admin":
            return True
        if obj.teacher_id is not None:
            return obj.teacher_id == user.id
        # Unassigned: any teacher may validate (and will become the assigned teacher).
        return user.role == "teacher"


class IsInternshipParty(BasePermission):
    """Object-level: any party to the internship (student/company/teacher) or admin.

    Works for an Internship, Task, or Report instance.
    Any teacher may also access an unassigned pending-validation internship.
    """

    message = "This resource is not available."

    def has_object_permission(self, request, view, obj) -> bool:
        user = request.user
        if not (user and user.is_authenticated):
            return False
        internship = _internship_of(obj)
        if user.role == "admin":
            return True
        if user.id in (internship.student_id, internship.company_id, internship.teacher_id):
            return True
        return (
            user.role == "teacher"
            and internship.teacher_id is None
            and internship.status == Internship.Status.PENDING_ACADEMIC_VALIDATION
        )


class IsInternshipStudent(BasePermission):
    """Object-level: the internship's student (task/report submission)."""

    message = "Only the internship's student can do this."

    def has_object_permission(self, request, view, obj) -> bool:
        user = request.user
        if not (user and user.is_authenticated):
            return False
        return _internship_of(obj).student_id == user.id


class IsInternshipSupervisor(BasePermission):
    """Object-level: the internship's company or assigned teacher (or admin)."""

    message = "Only the company or assigned teacher can do this."

    def has_object_permission(self, request, view, obj) -> bool:
        user = request.user
        if not (user and user.is_authenticated):
            return False
        return _is_supervisor(user, _internship_of(obj))


class IsTaskOwner(BasePermission):
    """Object-level: the user who created the task."""

    message = "Only the task's creator can edit it."

    def has_object_permission(self, request, view, obj) -> bool:
        user = request.user
        if not (user and user.is_authenticated):
            return False
        return obj.created_by_id == user.id
