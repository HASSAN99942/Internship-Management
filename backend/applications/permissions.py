"""Authorization for applications."""

from rest_framework.permissions import BasePermission

from .models import Application


class IsApplicationStudentOwner(BasePermission):
    """Object-level: only the student who submitted the application."""

    message = "You can only act on your own application."

    def has_object_permission(self, request, view, obj: Application) -> bool:
        user = request.user
        return bool(user and user.is_authenticated and obj.student_id == user.id)


class IsOfferOwnerForApplication(BasePermission):
    """Object-level: the company that owns the application's offer, or an admin."""

    message = "You can only act on applications to your own offers."

    def has_object_permission(self, request, view, obj: Application) -> bool:
        user = request.user
        if not (user and user.is_authenticated):
            return False
        return user.role == "admin" or obj.offer.company_id == user.id


class CanViewApplication(BasePermission):
    """Object-level: the owning student, the offer's company, or an admin."""

    message = "This application is not available."

    def has_object_permission(self, request, view, obj: Application) -> bool:
        user = request.user
        if not (user and user.is_authenticated):
            return False
        return (
            user.role == "admin"
            or obj.student_id == user.id
            or obj.offer.company_id == user.id
        )
