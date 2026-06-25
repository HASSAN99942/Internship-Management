"""Business logic for accounts — the only place that writes account data.

Views validate input via serializers, then call these functions. Multi-step
writes are wrapped in ``transaction.atomic`` (CLAUDE.md conventions).
"""

from django.db import transaction
from django.utils import timezone
from rest_framework.exceptions import PermissionDenied, ValidationError

from .models import (
    CompanyProfile,
    StudentProfile,
    SupervisionRequest,
    TeacherProfile,
    User,
)

PROFILE_MODELS = {
    User.Role.STUDENT: StudentProfile,
    User.Role.COMPANY: CompanyProfile,
    User.Role.TEACHER: TeacherProfile,
}


@transaction.atomic
def register_user(
    *,
    email: str,
    password: str,
    role: str,
    first_name: str = "",
    last_name: str = "",
    profile: dict | None = None,
) -> User:
    """Create a user and its matching role profile atomically."""
    profile = profile or {}
    user = User.objects.create_user(
        email=email,
        password=password,
        role=role,
        first_name=first_name,
        last_name=last_name,
    )
    PROFILE_MODELS[role].objects.create(user=user, **profile)
    return user


@transaction.atomic
def update_me(
    *,
    user: User,
    first_name: str | None = None,
    last_name: str | None = None,
    profile: dict | None = None,
) -> User:
    """Apply a partial update to the user and/or its role profile."""
    update_fields: list[str] = []
    if first_name is not None:
        user.first_name = first_name
        update_fields.append("first_name")
    if last_name is not None:
        user.last_name = last_name
        update_fields.append("last_name")
    if update_fields:
        user.save(update_fields=update_fields)

    if profile:
        _update_profile(user, profile)

    return user


def _update_profile(user: User, profile_data: dict) -> None:
    profile_obj = getattr(user, f"{user.role}_profile", None)
    if profile_obj is None:
        return
    for attr, value in profile_data.items():
        setattr(profile_obj, attr, value)
    profile_obj.save()


@transaction.atomic
def assign_teacher(
    *,
    profile: StudentProfile,
    teacher_user: User | None,
    by_user: User,
) -> StudentProfile:
    """Set (or clear) a student's assigned teacher.

    Admins may assign anyone to anyone. Teachers may only claim a student for
    themselves (or release one already theirs) — they cannot assign to another
    teacher or take a student already supervised by someone else.
    """
    if teacher_user is not None and teacher_user.role != User.Role.TEACHER:
        raise ValidationError("Assigned user must be a teacher.")

    if by_user.role == User.Role.TEACHER:
        if teacher_user is not None and teacher_user.id != by_user.id:
            raise PermissionDenied(
                "Teachers can only assign students to themselves."
            )
        current = profile.assigned_teacher_id
        if current is not None and current != by_user.id:
            raise PermissionDenied("This student is assigned to another teacher.")

    profile.assigned_teacher = teacher_user
    profile.save(update_fields=["assigned_teacher", "updated_at"])
    return profile


# --------------------------------------------------------------------------- #
# Supervision requests (mutual-consent flow). Either party initiates; the other
# validates. State machine: pending -> accepted | rejected | cancelled.
# --------------------------------------------------------------------------- #
@transaction.atomic
def request_supervision(
    *, student: User, teacher: User, initiated_by: str
) -> SupervisionRequest:
    """Create a pending supervision request.

    Rejects if the student already has a supervisor or already has a pending
    request (one outstanding request per student).
    """
    # Read the profile fresh (authoritative DB state) rather than a possibly
    # cached reverse relation on the passed-in user instance.
    profile = StudentProfile.objects.get(user=student)
    if profile.assigned_teacher_id is not None:
        raise ValidationError("This student already has an academic supervisor.")
    if SupervisionRequest.objects.filter(
        student=student, status=SupervisionRequest.Status.PENDING
    ).exists():
        raise ValidationError(
            "There is already a pending supervision request for this student."
        )
    return SupervisionRequest.objects.create(
        student=student,
        teacher=teacher,
        initiated_by=initiated_by,
        status=SupervisionRequest.Status.PENDING,
    )


@transaction.atomic
def accept_supervision_request(*, req: SupervisionRequest) -> SupervisionRequest:
    """Accept a pending request and set the student's assigned teacher."""
    if req.status != SupervisionRequest.Status.PENDING:
        raise ValidationError("Only a pending request can be accepted.")
    profile = req.student.student_profile
    if profile.assigned_teacher_id is not None:
        raise ValidationError("This student already has an academic supervisor.")
    profile.assigned_teacher = req.teacher
    profile.save(update_fields=["assigned_teacher", "updated_at"])
    req.status = SupervisionRequest.Status.ACCEPTED
    req.decided_at = timezone.now()
    req.save(update_fields=["status", "decided_at", "updated_at"])
    return req


@transaction.atomic
def reject_supervision_request(*, req: SupervisionRequest) -> SupervisionRequest:
    """Reject a pending request."""
    if req.status != SupervisionRequest.Status.PENDING:
        raise ValidationError("Only a pending request can be rejected.")
    req.status = SupervisionRequest.Status.REJECTED
    req.decided_at = timezone.now()
    req.save(update_fields=["status", "decided_at", "updated_at"])
    return req


@transaction.atomic
def cancel_supervision_request(*, req: SupervisionRequest) -> SupervisionRequest:
    """Cancel a pending request (by its initiator)."""
    if req.status != SupervisionRequest.Status.PENDING:
        raise ValidationError("Only a pending request can be cancelled.")
    req.status = SupervisionRequest.Status.CANCELLED
    req.decided_at = timezone.now()
    req.save(update_fields=["status", "decided_at", "updated_at"])
    return req
