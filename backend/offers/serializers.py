"""Validation & representation for offers.

Write and read shapes are separate: companies set only the editable fields
(company is taken from the request user; status changes go through the
publish/close actions). Serializers validate/represent only — writes happen in
services.py.
"""

from datetime import date

from rest_framework import serializers

from .models import Offer


class CompanySummarySerializer(serializers.Serializer):
    """Minimal company info embedded in offer responses."""

    id = serializers.IntegerField()
    email = serializers.EmailField()
    company_name = serializers.SerializerMethodField()

    def get_company_name(self, user) -> str:
        profile = getattr(user, "company_profile", None)
        return profile.company_name if profile else ""


class OfferReadSerializer(serializers.ModelSerializer):
    """List/detail representation (read-only)."""

    company = CompanySummarySerializer(read_only=True)
    is_open = serializers.BooleanField(read_only=True)

    class Meta:
        model = Offer
        fields = [
            "id",
            "company",
            "title",
            "description",
            "skills",
            "location",
            "duration_weeks",
            "start_date",
            "positions",
            "status",
            "is_open",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields


class OfferWriteSerializer(serializers.ModelSerializer):
    """Create/update input. Excludes company and status by design."""

    duration_weeks = serializers.IntegerField(min_value=1)
    positions = serializers.IntegerField(min_value=1, required=False)

    class Meta:
        model = Offer
        fields = [
            "title",
            "description",
            "skills",
            "location",
            "duration_weeks",
            "start_date",
            "positions",
        ]
        extra_kwargs = {
            "title": {"required": True},
            "description": {"required": True},
            "skills": {"required": True},
            "location": {"required": True},
            "start_date": {"required": True},
        }

    def validate_start_date(self, value):
        if value < date.today():
            raise serializers.ValidationError("Start date cannot be in the past.")
        return value
