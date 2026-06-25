"""Authorization for offers (reuses core role permissions for create/mine)."""

from rest_framework.permissions import BasePermission

from .models import Offer


class IsOfferOwnerOrAdmin(BasePermission):
    """Object-level: only the owning company or an admin may modify an offer."""

    message = "You may only modify your own offers."

    def has_object_permission(self, request, view, obj: Offer) -> bool:
        user = request.user
        if not (user and user.is_authenticated):
            return False
        return user.role == "admin" or obj.company_id == user.id


class CanViewOffer(BasePermission):
    """Object-level: published offers are visible to any authenticated user;
    drafts/closed offers only to the owning company or an admin."""

    message = "This offer is not available."

    def has_object_permission(self, request, view, obj: Offer) -> bool:
        user = request.user
        if not (user and user.is_authenticated):
            return False
        if obj.status == Offer.Status.PUBLISHED:
            return True
        return user.role == "admin" or obj.company_id == user.id
