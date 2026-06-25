"""Business logic for applications — the only place that writes this data.

The accept flow spans multiple models and runs in a single transaction
(SRS NFR-06): set the application accepted, create the Internship agreement,
and create its MessageThread — all or nothing.
"""

from datetime import timedelta

from django.db import transaction
from django.utils import timezone
from rest_framework.exceptions import PermissionDenied, ValidationError

from offers.models import Offer

from notifications import events

from .models import Application


def _accepted_count(offer: Offer) -> int:
    return Application.objects.filter(
        offer=offer, status=Application.Status.ACCEPTED
    ).count()


@transaction.atomic
def apply_to_offer(*, student, offer: Offer, data: dict) -> Application:
    """Create a pending application. Enforces OFFER-05 and APP-02."""
    if offer.status != Offer.Status.PUBLISHED:
        raise ValidationError("This offer is not open for applications.")
    if _accepted_count(offer) >= offer.positions:
        raise ValidationError("This offer has no remaining positions.")
    if Application.objects.filter(offer=offer, student=student).exists():
        raise ValidationError("You have already applied to this offer.")

    application = Application.objects.create(
        offer=offer,
        student=student,
        cover_message=data["cover_message"],
        cv_file=data.get("cv_file"),
        status=Application.Status.PENDING,
    )
    events.notify_application_received(application)
    return application


@transaction.atomic
def withdraw_application(*, application: Application, by_user) -> Application:
    """Withdraw a pending application (owning student only)."""
    if application.student_id != by_user.id:
        raise PermissionDenied("You can only withdraw your own application.")
    if application.status != Application.Status.PENDING:
        raise ValidationError("Only a pending application can be withdrawn.")
    application.status = Application.Status.WITHDRAWN
    application.save(update_fields=["status", "updated_at"])
    return application


@transaction.atomic
def reject_application(*, application: Application) -> Application:
    """Reject a pending application (owning company; checked in the view)."""
    if application.status != Application.Status.PENDING:
        raise ValidationError("Only a pending application can be rejected.")
    application.status = Application.Status.REJECTED
    application.decided_at = timezone.now()
    application.save(update_fields=["status", "decided_at", "updated_at"])
    events.notify_application_rejected(application)
    return application


@transaction.atomic
def accept_application(*, application: Application):
    """Accept an application and create the internship agreement + thread.

    Returns the created Internship. Atomic: application + internship + thread
    are created together or not at all.
    """
    # Imported here to avoid a model-level import cycle across apps.
    from internships.models import Internship
    from messaging.models import MessageThread

    if application.status != Application.Status.PENDING:
        raise ValidationError("Only a pending application can be accepted.")

    application.status = Application.Status.ACCEPTED
    application.decided_at = timezone.now()
    application.save(update_fields=["status", "decided_at", "updated_at"])

    offer = application.offer
    student = application.student
    teacher = getattr(
        getattr(student, "student_profile", None), "assigned_teacher", None
    )
    start_date = offer.start_date
    end_date = start_date + timedelta(weeks=offer.duration_weeks)

    internship = Internship.objects.create(
        application=application,
        student=student,
        company=offer.company,
        teacher=teacher,
        status=Internship.Status.PENDING_ACADEMIC_VALIDATION,
        start_date=start_date,
        end_date=end_date,
    )
    MessageThread.objects.create(internship=internship)

    events.notify_application_accepted(application)
    if internship.teacher_id is not None:
        events.notify_agreement_to_validate(internship)
    return internship
