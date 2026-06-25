"""Validation & representation for internships, tasks, and reports.

Reads shape the dashboard; writes validate input only (services do the writing).
"""

from datetime import date

from rest_framework import serializers

from core.validators import validate_upload

from .models import Internship, Report, Task


class PartySummarySerializer(serializers.Serializer):
    """Minimal user info for a party to the internship."""

    id = serializers.IntegerField()
    email = serializers.EmailField()
    first_name = serializers.CharField()
    last_name = serializers.CharField()


class InternshipReadSerializer(serializers.ModelSerializer):
    student = PartySummarySerializer(read_only=True)
    company = PartySummarySerializer(read_only=True)
    teacher = PartySummarySerializer(read_only=True)
    offer_title = serializers.CharField(
        source="application.offer.title", read_only=True
    )

    class Meta:
        model = Internship
        fields = [
            "id",
            "application",
            "offer_title",
            "student",
            "company",
            "teacher",
            "status",
            "start_date",
            "end_date",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields


# --------------------------------------------------------------------------- #
# Tasks
# --------------------------------------------------------------------------- #
class TaskReadSerializer(serializers.ModelSerializer):
    created_by = PartySummarySerializer(read_only=True)

    class Meta:
        model = Task
        fields = [
            "id",
            "internship",
            "created_by",
            "title",
            "description",
            "due_date",
            "status",
            "submission_note",
            "submission_file",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields


class TaskWriteSerializer(serializers.ModelSerializer):
    """Create / generic update of a task by a supervisor."""

    class Meta:
        model = Task
        fields = ["title", "description", "due_date"]
        extra_kwargs = {"title": {"required": True}}

    def validate_due_date(self, value):
        if value is not None and value < date.today():
            raise serializers.ValidationError("Due date cannot be in the past.")
        return value


class TaskSubmitSerializer(serializers.Serializer):
    """Student submission: a note and/or a file."""

    submission_note = serializers.CharField(required=False, allow_blank=True)
    submission_file = serializers.FileField(required=False)

    def validate_submission_file(self, value):
        return validate_upload(value)


# --------------------------------------------------------------------------- #
# Reports
# --------------------------------------------------------------------------- #
class ReportReadSerializer(serializers.ModelSerializer):
    student = PartySummarySerializer(read_only=True)

    class Meta:
        model = Report
        fields = [
            "id",
            "internship",
            "student",
            "title",
            "content",
            "file",
            "period",
            "status",
            "feedback",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields


class ReportSubmitSerializer(serializers.ModelSerializer):
    file = serializers.FileField(required=False)

    class Meta:
        model = Report
        fields = ["title", "content", "period", "file"]
        extra_kwargs = {
            "title": {"required": True},
            "content": {"required": True},
            "period": {"required": True},
        }

    def validate_file(self, value):
        return validate_upload(value)


class RequestChangesSerializer(serializers.Serializer):
    """Feedback accompanying a request-changes action (required for reports)."""

    feedback = serializers.CharField()


# --------------------------------------------------------------------------- #
# Dashboard aggregate
# --------------------------------------------------------------------------- #
class ProgressSerializer(serializers.Serializer):
    tasks_total = serializers.IntegerField()
    tasks_validated = serializers.IntegerField()
    tasks_validated_pct = serializers.IntegerField()
    reports_total = serializers.IntegerField()
    reports_validated = serializers.IntegerField()
    reports_validated_pct = serializers.IntegerField()


class InternshipDashboardSerializer(serializers.Serializer):
    """Aggregate returned by GET /internships/{id}/."""

    internship = InternshipReadSerializer()
    tasks = TaskReadSerializer(many=True)
    reports = ReportReadSerializer(many=True)
    progress = ProgressSerializer()
