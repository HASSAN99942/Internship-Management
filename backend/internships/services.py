"""Business logic for internships — the only place that writes this data."""

from django.db import transaction
from rest_framework.exceptions import PermissionDenied, ValidationError

from notifications import events

from .models import Internship, Report, Task


def _require_active(internship: Internship) -> None:
    if internship.status != Internship.Status.ACTIVE:
        raise ValidationError("This internship is not active.")


@transaction.atomic
def validate_internship(*, internship: Internship, by_user) -> Internship:
    """Academic validation: pending_academic_validation -> active.

    The assigned teacher, any teacher when unassigned, or an admin may validate.
    If the internship had no assigned teacher, the validating teacher is assigned.
    """
    if internship.status != Internship.Status.PENDING_ACADEMIC_VALIDATION:
        raise ValidationError(
            "This internship is not awaiting academic validation."
        )
    update_fields = ["status", "updated_at"]
    if internship.teacher_id is None and by_user.role == "teacher":
        internship.teacher = by_user
        update_fields.append("teacher")
    internship.status = Internship.Status.ACTIVE
    internship.save(update_fields=update_fields)
    events.notify_internship_activated(internship)
    return internship


@transaction.atomic
def cancel_internship(*, internship: Internship) -> Internship:
    """Stub for later phases: mark an internship cancelled."""
    internship.status = Internship.Status.CANCELLED
    internship.save(update_fields=["status", "updated_at"])
    return internship


# --------------------------------------------------------------------------- #
# Tasks (MON-02..04). State machine:
#   open -> submitted (student); changes_requested -> submitted (student)
#   submitted -> validated | changes_requested (supervisor)
# --------------------------------------------------------------------------- #
@transaction.atomic
def create_task(*, internship: Internship, by_user, data: dict) -> Task:
    """Create a task. Caller authorization is enforced by the view's permission."""
    _require_active(internship)
    task = Task.objects.create(
        internship=internship,
        created_by=by_user,
        title=data["title"],
        description=data.get("description", ""),
        due_date=data.get("due_date"),
        status=Task.Status.OPEN,
    )
    events.notify_task_assigned(task)
    return task


@transaction.atomic
def update_task(*, task: Task, data: dict) -> Task:
    """Generic update of a task's editable fields (title/description/due_date)."""
    _require_active(task.internship)
    for field in ("title", "description", "due_date"):
        if field in data:
            setattr(task, field, data[field])
    task.save()
    return task


@transaction.atomic
def submit_task(*, task: Task, note: str = "", file=None) -> Task:
    """Student submits work for a task (from open or changes_requested)."""
    _require_active(task.internship)
    if task.status not in (Task.Status.OPEN, Task.Status.CHANGES_REQUESTED):
        raise ValidationError("This task cannot be submitted in its current state.")
    task.submission_note = note or ""
    if file is not None:
        task.submission_file = file
    task.status = Task.Status.SUBMITTED
    task.save()
    events.notify_task_submitted(task)
    return task


@transaction.atomic
def validate_task(*, task: Task) -> Task:
    """Supervisor validates a submitted task."""
    _require_active(task.internship)
    if task.status != Task.Status.SUBMITTED:
        raise ValidationError("Only a submitted task can be validated.")
    task.status = Task.Status.VALIDATED
    task.save(update_fields=["status", "updated_at"])
    events.notify_task_validated(task)
    return task


@transaction.atomic
def request_task_changes(*, task: Task) -> Task:
    """Supervisor returns a submitted task for changes."""
    _require_active(task.internship)
    if task.status != Task.Status.SUBMITTED:
        raise ValidationError(
            "Only a submitted task can be returned for changes."
        )
    task.status = Task.Status.CHANGES_REQUESTED
    task.save(update_fields=["status", "updated_at"])
    events.notify_task_changes_requested(task)
    return task


# --------------------------------------------------------------------------- #
# Reports (MON-05..06). Submitted on creation; supervisor validates or returns.
# --------------------------------------------------------------------------- #
@transaction.atomic
def submit_report(*, internship: Internship, by_student, data: dict) -> Report:
    """Student submits a periodic report."""
    _require_active(internship)
    report = Report.objects.create(
        internship=internship,
        student=by_student,
        title=data["title"],
        content=data["content"],
        period=data["period"],
        file=data.get("file"),
        status=Report.Status.SUBMITTED,
    )
    events.notify_report_submitted(report)
    return report


@transaction.atomic
def validate_report(*, report: Report) -> Report:
    """Supervisor validates a submitted report."""
    _require_active(report.internship)
    if report.status != Report.Status.SUBMITTED:
        raise ValidationError("Only a submitted report can be validated.")
    report.status = Report.Status.VALIDATED
    report.save(update_fields=["status", "updated_at"])
    events.notify_report_validated(report)
    return report


@transaction.atomic
def request_report_changes(*, report: Report, feedback: str) -> Report:
    """Supervisor returns a submitted report with feedback."""
    _require_active(report.internship)
    if report.status != Report.Status.SUBMITTED:
        raise ValidationError(
            "Only a submitted report can be returned for changes."
        )
    report.status = Report.Status.CHANGES_REQUESTED
    report.feedback = feedback
    report.save(update_fields=["status", "feedback", "updated_at"])
    events.notify_report_changes_requested(report)
    return report
