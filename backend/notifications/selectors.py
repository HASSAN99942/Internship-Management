"""Read queries for notifications."""

from .models import Notification


def list_notifications(user):
    """The user's notifications, most recent first."""
    return Notification.objects.filter(user=user).order_by("-created_at")


def unread_count(user) -> int:
    return Notification.objects.filter(user=user, is_read=False).count()
