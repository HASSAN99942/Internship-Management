"""Read queries for messaging.

Thread-list aggregates (unread count, last message, last activity) are computed
with subqueries — not per-thread Python loops — to avoid N+1 and join
multiplication. Participant objects come from a single select_related.
"""

from django.db.models import Count, DateTimeField, IntegerField, OuterRef, Subquery
from django.db.models.functions import Coalesce
from django.shortcuts import get_object_or_404

from .models import Message, MessageThread

_THREAD_RELATIONS = (
    "internship",
    "internship__student",
    "internship__company",
    "internship__teacher",
    "internship__application",
    "internship__application__offer",
)


def _participants(internship):
    parties = [internship.student, internship.company]
    if internship.teacher_id:
        parties.append(internship.teacher)
    return parties


def thread_header(thread: MessageThread) -> dict:
    internship = thread.internship
    return {
        "id": thread.id,
        "internship_id": internship.id,
        "offer_title": internship.application.offer.title,
        "participants": _participants(internship),
    }


def list_threads_for_user(user):
    """Threads the user is party to, annotated and ordered by recent activity."""
    threads = MessageThread.objects.select_related(*_THREAD_RELATIONS)
    if user.role == "admin":
        pass
    elif user.role == "student":
        threads = threads.filter(internship__student=user)
    elif user.role == "company":
        threads = threads.filter(internship__company=user)
    elif user.role == "teacher":
        threads = threads.filter(internship__teacher=user)
    else:
        threads = threads.none()

    latest = Message.objects.filter(thread=OuterRef("pk")).order_by("-created_at")
    unread = (
        Message.objects.filter(thread=OuterRef("pk"), is_read=False)
        .exclude(sender=user)
        .order_by()
        .values("thread")
        .annotate(c=Count("*"))
        .values("c")
    )
    threads = threads.annotate(
        last_message=Subquery(latest.values("body")[:1]),
        last_activity=Coalesce(
            Subquery(latest.values("created_at")[:1], output_field=DateTimeField()),
            "created_at",
        ),
        unread_count=Coalesce(
            Subquery(unread, output_field=IntegerField()), 0
        ),
    ).order_by("-last_activity")

    return [
        {
            **thread_header(thread),
            "unread_count": thread.unread_count,
            "last_message": thread.last_message,
            "last_activity": thread.last_activity,
        }
        for thread in threads
    ]


def list_messages(thread: MessageThread):
    """Messages in a thread, oldest first."""
    return thread.messages.select_related("sender").order_by("created_at")


def get_thread(thread_id) -> MessageThread:
    """Fetch a thread (404 if missing). Participation is checked in views."""
    return get_object_or_404(
        MessageThread.objects.select_related(*_THREAD_RELATIONS), pk=thread_id
    )
