"""Reusable authorization primitives shared across apps.

Role rules are enforced server-side (SRS §3). Concrete apps compose these
classes; they should not re-implement role checks themselves.
"""

from rest_framework.permissions import BasePermission


class RoleRequired(BasePermission):
    """Base permission granting access only to listed roles.

    Subclass and set ``allowed_roles``; an empty tuple denies everyone.
    """

    allowed_roles: tuple[str, ...] = ()

    def has_permission(self, request, view) -> bool:
        user = request.user
        return bool(
            user
            and user.is_authenticated
            and getattr(user, "role", None) in self.allowed_roles
        )


class IsStudent(RoleRequired):
    allowed_roles = ("student",)


class IsCompany(RoleRequired):
    allowed_roles = ("company",)


class IsTeacher(RoleRequired):
    allowed_roles = ("teacher",)


class IsAdmin(RoleRequired):
    allowed_roles = ("admin",)
