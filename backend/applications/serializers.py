"""Validation & representation for applications.

Writes happen in services.py; these serializers validate input and shape
output only.
"""

from rest_framework import serializers

from .models import Application

# CV upload constraints (APP-01 / files & validation).
ALLOWED_CV_EXTENSIONS = ("pdf", "doc", "docx")
MAX_CV_SIZE_BYTES = 5 * 1024 * 1024  # 5 MB


class ApplicantSummarySerializer(serializers.Serializer):
    """Minimal applicant info embedded in application responses."""

    id = serializers.IntegerField()
    email = serializers.EmailField()
    first_name = serializers.CharField()
    last_name = serializers.CharField()


class OfferSummarySerializer(serializers.Serializer):
    """Minimal offer info embedded in application responses."""

    id = serializers.IntegerField()
    title = serializers.CharField()


class ApplicationReadSerializer(serializers.ModelSerializer):
    student = ApplicantSummarySerializer(read_only=True)
    offer = OfferSummarySerializer(read_only=True)
    cv_file = serializers.FileField(read_only=True)

    class Meta:
        model = Application
        fields = [
            "id",
            "offer",
            "student",
            "cover_message",
            "cv_file",
            "status",
            "decided_at",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields


class ApplyWriteSerializer(serializers.Serializer):
    """Input for POST /offers/{id}/apply/ (multipart: cover_message + cv_file)."""

    cover_message = serializers.CharField()
    cv_file = serializers.FileField(required=False)

    def validate_cv_file(self, value):
        if value is None:
            return value
        name = (value.name or "").lower()
        extension = name.rsplit(".", 1)[-1] if "." in name else ""
        if extension not in ALLOWED_CV_EXTENSIONS:
            raise serializers.ValidationError(
                "CV must be a PDF, DOC or DOCX file."
            )
        if value.size > MAX_CV_SIZE_BYTES:
            raise serializers.ValidationError("CV must be 5 MB or smaller.")
        return value
