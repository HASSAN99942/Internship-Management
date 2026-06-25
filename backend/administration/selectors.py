"""Cross-app read aggregates for the admin stats endpoint (ADMIN-04).

This app owns the cross-cutting reads so the foundational apps don't depend on
each other for reporting.
"""

from django.db.models import Count

from accounts.models import User
from applications.models import Application
from internships.models import Internship
from offers.models import Offer


def _counts_by(queryset, field: str, choices) -> dict:
    """Count rows grouped by ``field``, with every choice present (0-filled)."""
    counts = {value: 0 for value in choices}
    for row in queryset.values(field).annotate(n=Count("id")):
        counts[row[field]] = row["n"]
    return counts


def get_stats() -> dict:
    users_by_role = _counts_by(
        User.objects.all(), "role", [r.value for r in User.Role]
    )
    offers_by_status = _counts_by(
        Offer.objects.all(), "status", [s.value for s in Offer.Status]
    )
    applications_by_status = _counts_by(
        Application.objects.all(), "status", [s.value for s in Application.Status]
    )
    internships_by_status = _counts_by(
        Internship.objects.all(), "status", [s.value for s in Internship.Status]
    )
    return {
        "users_by_role": users_by_role,
        "offers_by_status": offers_by_status,
        "applications_by_status": applications_by_status,
        "internships_by_status": internships_by_status,
        "totals": {
            "users": sum(users_by_role.values()),
            "offers": sum(offers_by_status.values()),
            "applications": sum(applications_by_status.values()),
            "active_internships": internships_by_status.get("active", 0),
            "completed_internships": internships_by_status.get("completed", 0),
        },
    }
