"""Read queries for accounts."""

from django.db.models import Q
from django.shortcuts import get_object_or_404

from .models import StudentProfile, SupervisionRequest, User


def get_me(user: User) -> User:
    """Return the user with its role profiles prefetched for serialization."""
    return User.objects.select_related(
        "student_profile",
        "student_profile__assigned_teacher",
        "company_profile",
        "teacher_profile",
    ).get(pk=user.pk)


def list_students_for(user: User):
    """Student profiles visible for supervision.

    Admin sees all; a teacher sees only unassigned students plus their own
    (so other teachers' rosters aren't exposed).
    """
    base = StudentProfile.objects.select_related("user", "assigned_teacher").order_by(
        "user__first_name", "user__last_name", "user__email"
    )
    if user.role == "admin":
        return base
    if user.role == "teacher":
        return base.filter(Q(assigned_teacher__isnull=True) | Q(assigned_teacher=user))
    return base.none()


def get_student_profile(student_user_id) -> StudentProfile:
    """Fetch a student's profile by their user id (404 if not a student)."""
    return get_object_or_404(
        StudentProfile.objects.select_related("user", "assigned_teacher"),
        user_id=student_user_id,
    )


def get_teacher(teacher_user_id) -> User:
    """Fetch a teacher user by id (404 if not a teacher)."""
    return get_object_or_404(
        User, pk=teacher_user_id, role=User.Role.TEACHER
    )


def list_teachers():
    """All teachers, for the student's supervisor picker (ADMIN-03)."""
    return (
        User.objects.filter(role=User.Role.TEACHER)
        .select_related("teacher_profile")
        .order_by("first_name", "last_name", "email")
    )


def list_supervision_requests_for_user(user: User):
    """Supervision requests the user is party to, newest first (role-scoped)."""
    base = SupervisionRequest.objects.select_related("student", "teacher").order_by(
        "-created_at"
    )
    if user.role == User.Role.ADMIN:
        return base
    if user.role == User.Role.STUDENT:
        return base.filter(student=user)
    if user.role == User.Role.TEACHER:
        return base.filter(teacher=user)
    return base.none()


def get_supervision_request(request_id) -> SupervisionRequest:
    """Fetch a supervision request (404 if missing). Visibility checked in views."""
    return get_object_or_404(
        SupervisionRequest.objects.select_related("student", "teacher"),
        pk=request_id,
    )
