"""Validation & representation for messaging.

Writes happen in services.py; these serializers validate input and shape output.
"""

from rest_framework import serializers

from .models import Message


class PartySummarySerializer(serializers.Serializer):
    """Minimal user info for a sender / thread participant."""

    id = serializers.IntegerField()
    email = serializers.EmailField()
    first_name = serializers.CharField()
    last_name = serializers.CharField()


class MessageSerializer(serializers.ModelSerializer):
    sender = PartySummarySerializer(read_only=True)

    class Meta:
        model = Message
        fields = ["id", "thread", "sender", "body", "is_read", "created_at"]
        read_only_fields = fields


class SendMessageSerializer(serializers.Serializer):
    """Input for POST /threads/{id}/messages/."""

    body = serializers.CharField(trim_whitespace=True)

    def validate_body(self, value: str) -> str:
        if not value.strip():
            raise serializers.ValidationError("Message body cannot be empty.")
        return value


class ThreadListSerializer(serializers.Serializer):
    """A thread row for the conversation list (annotated by the selector)."""

    id = serializers.IntegerField()
    internship_id = serializers.IntegerField()
    offer_title = serializers.CharField()
    participants = PartySummarySerializer(many=True)
    unread_count = serializers.IntegerField()
    last_message = serializers.CharField(allow_null=True)
    last_activity = serializers.DateTimeField()


class ThreadDetailSerializer(serializers.Serializer):
    """Thread header: participants + internship reference."""

    id = serializers.IntegerField()
    internship_id = serializers.IntegerField()
    offer_title = serializers.CharField()
    participants = PartySummarySerializer(many=True)
