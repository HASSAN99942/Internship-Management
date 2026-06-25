"""Read queries for internships, reused across views."""

from django.shortcuts import get_object_or_404

from .models import Internship, Report, Task

_WITH_RELATIONS = (
    "student",
    "company",
    "teacher",
    "application",
    "application__offer",
)


def list_internships_for_user(user):
    """Internships visible to the user, scoped by role."""
    base = Internship.objects.select_related(*_WITH_RELATIONS).order_by(
        "-created_at"
    )
    if user.role == "admin":
        return base
    if user.role == "student":
        return base.filter(student=user)
    if user.role == "company":
        return base.filter(company=user)
    if user.role == "teacher":
        from django.db.models import Q
        return base.filter(
            Q(teacher=user)
            | Q(teacher__isnull=True, status=Internship.Status.PENDING_ACADEMIC_VALIDATION)
        )
    return base.none()


def list_pending_validations(teacher):
    """Internships awaiting academic validation visible to this teacher.

    Includes both internships explicitly assigned to them and any unassigned
    agreements (teacher_id=None) that any teacher may pick up.
    """
    from django.db.models import Q
    return (
        Internship.objects.filter(
            Q(teacher=teacher) | Q(teacher__isnull=True),
            status=Internship.Status.PENDING_ACADEMIC_VALIDATION,
        )
        .select_related(*_WITH_RELATIONS)
        .order_by("-created_at")
    )


def get_internship(internship_id) -> Internship:
    """Fetch a single internship (404 if missing). Visibility checked in views."""
    return get_object_or_404(
        Internship.objects.select_related(*_WITH_RELATIONS), pk=internship_id
    )


# --------------------------------------------------------------------------- #
# Tasks & reports
# --------------------------------------------------------------------------- #
def list_tasks(internship: Internship):
    return internship.tasks.select_related("created_by").order_by("-created_at")


def list_reports(internship: Internship):
    return internship.reports.select_related("student").order_by("-created_at")


def get_task(task_id) -> Task:
    return get_object_or_404(
        Task.objects.select_related("internship", "created_by"), pk=task_id
    )


def get_report(report_id) -> Report:
    return get_object_or_404(
        Report.objects.select_related("internship", "student"), pk=report_id
    )


def _pct(part: int, total: int) -> int:
    return round(part / total * 100) if total else 0


def compute_progress(internship: Internship) -> dict:
    """Validated-task and validated-report progress for the dashboard (MON-08)."""
    tasks = internship.tasks.all()
    reports = internship.reports.all()
    tasks_total = len(tasks)
    tasks_validated = sum(1 for t in tasks if t.status == Task.Status.VALIDATED)
    reports_total = len(reports)
    reports_validated = sum(
        1 for r in reports if r.status == Report.Status.VALIDATED
    )
    return {
        "tasks_total": tasks_total,
        "tasks_validated": tasks_validated,
        "tasks_validated_pct": _pct(tasks_validated, tasks_total),
        "reports_total": reports_total,
        "reports_validated": reports_validated,
        "reports_validated_pct": _pct(reports_validated, reports_total),
    }


def get_internship_dashboard(internship: Internship) -> dict:
    """Aggregate for GET /internships/{id}/: parties + tasks + reports + progress."""
    return {
        "internship": internship,
        "tasks": list_tasks(internship),
        "reports": list_reports(internship),
        "progress": compute_progress(internship),
    }
