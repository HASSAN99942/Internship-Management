"""Typed notification emitters used by other apps' services.

Each helper reads attributes off a passed-in instance and calls ``notify``;
it imports no other app's models, so wiring these into existing services
introduces no circular imports. Recipients never include the actor.
"""

from .models import Notification
from .services import notify

Type = Notification.Type


def _name(user) -> str:
    full = f"{user.first_name} {user.last_name}".strip()
    return full or user.email


# --------------------------------------------------------------------------- #
# Applications
# --------------------------------------------------------------------------- #
def notify_application_received(application) -> None:
    offer = application.offer
    notify(
        user=offer.company,
        type=Type.APPLICATION_RECEIVED,
        payload={
            "message": f"New application from {_name(application.student)} for “{offer.title}”.",
            "route": "/company/applications",
            "application_id": application.id,
            "offer_id": offer.id,
        },
    )


def notify_application_accepted(application) -> None:
    notify(
        user=application.student,
        type=Type.APPLICATION_ACCEPTED,
        payload={
            "message": f"Your application for “{application.offer.title}” was accepted.",
            "route": "/applications",
            "application_id": application.id,
        },
    )


def notify_application_rejected(application) -> None:
    notify(
        user=application.student,
        type=Type.APPLICATION_REJECTED,
        payload={
            "message": f"Your application for “{application.offer.title}” was not retained.",
            "route": "/applications",
            "application_id": application.id,
        },
    )


# --------------------------------------------------------------------------- #
# Internships / agreements
# --------------------------------------------------------------------------- #
def notify_agreement_to_validate(internship) -> None:
    """Caller ensures the internship has an assigned teacher."""
    if internship.teacher_id is None:
        return
    notify(
        user=internship.teacher,
        type=Type.AGREEMENT_TO_VALIDATE,
        payload={
            "message": f"An internship agreement for {_name(internship.student)} awaits your validation.",
            "route": "/teacher/agreements",
            "internship_id": internship.id,
        },
    )


def notify_internship_activated(internship) -> None:
    title = internship.application.offer.title
    for user in (internship.student, internship.company):
        notify(
            user=user,
            type=Type.INTERNSHIP_ACTIVATED,
            payload={
                "message": f"The internship for “{title}” is now active.",
                "route": f"/internships/{internship.id}",
                "internship_id": internship.id,
            },
        )


# --------------------------------------------------------------------------- #
# Tasks
# --------------------------------------------------------------------------- #
def _supervisors(internship):
    """Company + assigned teacher (if any) — the supervising recipients."""
    users = [internship.company]
    if internship.teacher_id is not None:
        users.append(internship.teacher)
    return users


def notify_task_assigned(task) -> None:
    notify(
        user=task.internship.student,
        type=Type.TASK_ASSIGNED,
        payload={
            "message": f"New task assigned: “{task.title}”.",
            "route": f"/internships/{task.internship_id}",
            "task_id": task.id,
            "internship_id": task.internship_id,
        },
    )


def notify_task_submitted(task) -> None:
    for user in _supervisors(task.internship):
        notify(
            user=user,
            type=Type.TASK_SUBMITTED,
            payload={
                "message": f"Task submitted for review: “{task.title}”.",
                "route": f"/internships/{task.internship_id}",
                "task_id": task.id,
                "internship_id": task.internship_id,
            },
        )


def notify_task_validated(task) -> None:
    notify(
        user=task.internship.student,
        type=Type.TASK_VALIDATED,
        payload={
            "message": f"Your task “{task.title}” was validated.",
            "route": f"/internships/{task.internship_id}",
            "task_id": task.id,
            "internship_id": task.internship_id,
        },
    )


def notify_task_changes_requested(task) -> None:
    notify(
        user=task.internship.student,
        type=Type.TASK_CHANGES_REQUESTED,
        payload={
            "message": f"Changes requested on your task “{task.title}”.",
            "route": f"/internships/{task.internship_id}",
            "task_id": task.id,
            "internship_id": task.internship_id,
        },
    )


# --------------------------------------------------------------------------- #
# Reports
# --------------------------------------------------------------------------- #
def notify_report_submitted(report) -> None:
    for user in _supervisors(report.internship):
        notify(
            user=user,
            type=Type.REPORT_SUBMITTED,
            payload={
                "message": f"New report submitted: “{report.title}”.",
                "route": f"/internships/{report.internship_id}",
                "report_id": report.id,
                "internship_id": report.internship_id,
            },
        )


def notify_report_validated(report) -> None:
    notify(
        user=report.internship.student,
        type=Type.REPORT_VALIDATED,
        payload={
            "message": f"Your report “{report.title}” was validated.",
            "route": f"/internships/{report.internship_id}",
            "report_id": report.id,
            "internship_id": report.internship_id,
        },
    )


def notify_report_changes_requested(report) -> None:
    notify(
        user=report.internship.student,
        type=Type.REPORT_CHANGES_REQUESTED,
        payload={
            "message": f"Changes requested on your report “{report.title}”.",
            "route": f"/internships/{report.internship_id}",
            "report_id": report.id,
            "internship_id": report.internship_id,
        },
    )


# --------------------------------------------------------------------------- #
# Messaging
# --------------------------------------------------------------------------- #
def notify_new_message(message) -> None:
    internship = message.thread.internship
    sender = message.sender
    parties = [internship.student, internship.company]
    if internship.teacher_id is not None:
        parties.append(internship.teacher)
    for user in parties:
        if user.id == sender.id:
            continue
        notify(
            user=user,
            type=Type.NEW_MESSAGE,
            payload={
                "message": f"New message from {_name(sender)}.",
                "route": "/messages",
                "thread_id": message.thread_id,
                "internship_id": internship.id,
            },
        )


# --------------------------------------------------------------------------- #
# Evaluations
# --------------------------------------------------------------------------- #
def notify_evaluation_submitted(evaluation) -> None:
    """Notify the student when a company/teacher evaluates them.

    A student self-rating notifies no one (they are the actor)."""
    internship = evaluation.internship
    if evaluation.evaluator_id == internship.student_id:
        return
    notify(
        user=internship.student,
        type=Type.EVALUATION_SUBMITTED,
        payload={
            "message": "An evaluation of your internship was submitted.",
            "route": f"/internships/{internship.id}",
            "evaluation_id": evaluation.id,
            "internship_id": internship.id,
        },
    )
