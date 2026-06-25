from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.translation import gettext_lazy as _

from .forms import UserAdminChangeForm, UserAdminCreationForm
from .models import (
    CompanyProfile,
    StudentProfile,
    SupervisionRequest,
    TeacherProfile,
    User,
)


@admin.register(SupervisionRequest)
class SupervisionRequestAdmin(admin.ModelAdmin):
    list_display = ["id", "student", "teacher", "initiated_by", "status", "decided_at"]
    list_filter = ["status", "initiated_by"]
    search_fields = ["student__email", "teacher__email"]
    raw_id_fields = ["student", "teacher"]
    readonly_fields = ["created_at", "updated_at", "decided_at"]


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """Admin UI for the custom email-login User (the admin role's tooling)."""

    form = UserAdminChangeForm
    add_form = UserAdminCreationForm

    ordering = ["email"]
    list_display = ["email", "first_name", "last_name", "role", "is_active", "is_staff"]
    list_filter = ["role", "is_active", "is_staff"]
    search_fields = ["email", "first_name", "last_name"]

    fieldsets = (
        (None, {"fields": ("email", "password")}),
        (_("Personal info"), {"fields": ("first_name", "last_name", "role")}),
        (
            _("Permissions"),
            {
                "fields": (
                    "is_active",
                    "is_staff",
                    "is_superuser",
                    "groups",
                    "user_permissions",
                )
            },
        ),
        (_("Important dates"), {"fields": ("last_login", "date_joined")}),
    )
    readonly_fields = ["last_login", "date_joined"]
    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": ("email", "role", "password1", "password2"),
            },
        ),
    )


@admin.register(StudentProfile)
class StudentProfileAdmin(admin.ModelAdmin):
    list_display = ["user", "school", "program", "level", "assigned_teacher"]
    search_fields = ["user__email", "school", "program"]
    raw_id_fields = ["user", "assigned_teacher"]


@admin.register(CompanyProfile)
class CompanyProfileAdmin(admin.ModelAdmin):
    list_display = ["user", "company_name", "sector"]
    search_fields = ["user__email", "company_name"]
    raw_id_fields = ["user"]


@admin.register(TeacherProfile)
class TeacherProfileAdmin(admin.ModelAdmin):
    list_display = ["user", "department", "title"]
    search_fields = ["user__email", "department"]
    raw_id_fields = ["user"]
