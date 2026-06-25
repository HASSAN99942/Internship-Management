"""Filtering for the published offers list (OFFER-04)."""

import django_filters
from django.db.models import Q

from .models import Offer


class OfferFilter(django_filters.FilterSet):
    # Keyword search across title, description and skills.
    q = django_filters.CharFilter(method="filter_q")
    location = django_filters.CharFilter(field_name="location", lookup_expr="icontains")
    duration_weeks = django_filters.NumberFilter(field_name="duration_weeks")
    company = django_filters.NumberFilter(field_name="company_id")

    class Meta:
        model = Offer
        fields = ["q", "location", "duration_weeks", "company"]

    def filter_q(self, queryset, _name, value):
        return queryset.filter(
            Q(title__icontains=value)
            | Q(description__icontains=value)
            | Q(skills__icontains=value)
        )
