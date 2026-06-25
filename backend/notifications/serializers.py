"""Representation for notifications (read-only)."""

from rest_framework import serializers

from .models import Notification


class NotificationReadSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ["id", "type", "payload", "is_read", "created_at"]
        read_only_fields = fields
