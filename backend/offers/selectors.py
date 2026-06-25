"""Read queries for offers, reused across views."""

from django.shortcuts import get_object_or_404

from .filters import OfferFilter
from .models import Offer

_WITH_COMPANY = ("company", "company__company_profile")


def list_published_offers(filters=None):
    """Published offers, newest first, optionally narrowed by query filters.

    ``filters`` is a mapping/QueryDict (e.g. request.query_params); the
    django-filter FilterSet applies q/location/duration_weeks/company.
    """
    queryset = (
        Offer.objects.filter(status=Offer.Status.PUBLISHED)
        .select_related(*_WITH_COMPANY)
        .order_by("-created_at")
    )
    if filters:
        return OfferFilter(filters, queryset=queryset).qs
    return queryset


def list_company_offers(company_user):
    """All offers owned by a company, any status, newest first."""
    return (
        Offer.objects.filter(company=company_user)
        .select_related(*_WITH_COMPANY)
        .order_by("-created_at")
    )


def get_offer(offer_id) -> Offer:
    """Fetch a single offer (404 if missing). Visibility is checked by views."""
    return get_object_or_404(
        Offer.objects.select_related(*_WITH_COMPANY), pk=offer_id
    )
