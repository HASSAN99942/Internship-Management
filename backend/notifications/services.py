"""Business logic for notifications — the only place that writes this data.

``notify`` is the single creation helper. Earlier-phase services emit through
the typed wrappers in ``events.py`` (which call ``notify``), so callers stay
one-liners and payload/routing lives in one place.
"""

from .models import Notification


def notify(*, user, type: str, payload: dict | None = None) -> Notification:
    """Create a notification for ``user``. No-op-safe payload defaulting."""
    return Notification.objects.create(
        user=user, type=type, payload=payload or {}
    )


def mark_read(*, notification: Notification, user) -> Notification:
    """Mark one notification read (owner enforced by the view permission)."""
    if not notification.is_read:
        notification.is_read = True
        notification.save(update_fields=["is_read", "updated_at"])
    return notification


def mark_all_read(*, user) -> int:
    """Mark all of the user's unread notifications read; returns the count."""
    return Notification.objects.filter(user=user, is_read=False).update(
        is_read=True
    )
