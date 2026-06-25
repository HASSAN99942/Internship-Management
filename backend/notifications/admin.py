from django.contrib import admin

from .models import Notification


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ["id", "user", "type", "is_read", "created_at"]
    list_filter = ["type", "is_read"]
    search_fields = ["user__email"]
    raw_id_fields = ["user"]
    readonly_fields = ["created_at", "updated_at"]
