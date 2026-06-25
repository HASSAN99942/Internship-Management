"""Authorization for notifications."""

from rest_framework.permissions import BasePermission

from .models import Notification


class IsNotificationOwner(BasePermission):
    """Object-level: a user may only act on their own notifications."""

    message = "This notification is not available."

    def has_object_permission(self, request, view, obj: Notification) -> bool:
        user = request.user
        return bool(user and user.is_authenticated and obj.user_id == user.id)
