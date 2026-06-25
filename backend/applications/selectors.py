"""Read queries for applications, reused across views."""

from django.shortcuts import get_object_or_404

from .models import Application

_WITH_RELATIONS = ("offer", "student", "offer__company")


def list_my_applications(student):
    """Applications submitted by a student, newest first."""
    return (
        Application.objects.filter(student=student)
        .select_related(*_WITH_RELATIONS)
        .order_by("-created_at")
    )


def list_offer_applications(company):
    """Applications received across all offers owned by a company."""
    return (
        Application.objects.filter(offer__company=company)
        .select_related(*_WITH_RELATIONS)
        .order_by("-created_at")
    )


def get_application(application_id) -> Application:
    """Fetch a single application (404 if missing). Visibility checked in views."""
    return get_object_or_404(
        Application.objects.select_related(*_WITH_RELATIONS), pk=application_id
    )
