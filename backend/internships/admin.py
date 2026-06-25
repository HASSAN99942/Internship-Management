from django.contrib import admin

from .models import Internship, Report, Task


@admin.register(Internship)
class InternshipAdmin(admin.ModelAdmin):
    list_display = ["id", "student", "company", "teacher", "status", "start_date", "end_date"]
    list_filter = ["status"]
    search_fields = ["student__email", "company__email", "teacher__email"]
    raw_id_fields = ["application", "student", "company", "teacher"]
    readonly_fields = ["created_at", "updated_at"]


@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = ["id", "internship", "title", "status", "due_date", "created_by"]
    list_filter = ["status"]
    search_fields = ["title", "internship__student__email"]
    raw_id_fields = ["internship", "created_by"]
    readonly_fields = ["created_at", "updated_at"]


@admin.register(Report)
class ReportAdmin(admin.ModelAdmin):
    list_display = ["id", "internship", "title", "period", "status", "student"]
    list_filter = ["status"]
    search_fields = ["title", "student__email"]
    raw_id_fields = ["internship", "student"]
    readonly_fields = ["created_at", "updated_at"]
