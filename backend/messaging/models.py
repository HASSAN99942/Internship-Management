from django.conf import settings
from django.db import models

from core.models import TimeStampedModel


class MessageThread(TimeStampedModel):
    """One conversation tied to an internship (SRS §7, MSG-01).

    Created alongside the internship on application acceptance. Its participants
    are the internship's parties (student, company, assigned teacher).
    """

    internship = models.OneToOneField(
        "internships.Internship",
        on_delete=models.CASCADE,
        related_name="thread",
    )

    def __str__(self) -> str:
        return f"MessageThread<internship {self.internship_id}>"


class Message(TimeStampedModel):
    """A single message posted by a participant within a thread (MSG-01)."""

    thread = models.ForeignKey(
        MessageThread, on_delete=models.CASCADE, related_name="messages"
    )
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="sent_messages",
    )
    body = models.TextField()
    is_read = models.BooleanField(default=False)

    class Meta:
        ordering = ["created_at"]
        indexes = [
            models.Index(fields=["thread", "created_at"]),
            models.Index(fields=["thread", "is_read"]),
        ]

    def __str__(self) -> str:
        return f"Message<thread {self.thread_id} by {self.sender_id}>"
