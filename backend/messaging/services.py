"""Business logic for messaging — the only place that writes this data."""

from django.db import transaction
from rest_framework.exceptions import ValidationError

from notifications import events

from .models import Message, MessageThread


@transaction.atomic
def send_message(*, thread: MessageThread, sender, body: str) -> Message:
    """Post a message to a thread. Participation is checked by the view."""
    body = (body or "").strip()
    if not body:
        raise ValidationError("Message body cannot be empty.")
    message = Message.objects.create(thread=thread, sender=sender, body=body)
    events.notify_new_message(message)
    return message


@transaction.atomic
def mark_thread_read(*, thread: MessageThread, user) -> int:
    """Mark every message not sent by ``user`` as read (single bulk update).

    Returns the number of messages updated.
    """
    return (
        Message.objects.filter(thread=thread, is_read=False)
        .exclude(sender=user)
        .update(is_read=True)
    )


def get_or_create_thread(*, internship) -> MessageThread:
    """Return the internship's thread, creating it if somehow missing."""
    thread, _created = MessageThread.objects.get_or_create(internship=internship)
    return thread
