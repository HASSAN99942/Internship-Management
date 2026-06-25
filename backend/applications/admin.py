from django.contrib import admin

from .models import Application


@admin.register(Application)
class ApplicationAdmin(admin.ModelAdmin):
    list_display = ["id", "offer", "student", "status", "decided_at", "created_at"]
    list_filter = ["status"]
    search_fields = ["offer__title", "student__email"]
    raw_id_fields = ["offer", "student"]
    readonly_fields = ["created_at", "updated_at", "decided_at"]
