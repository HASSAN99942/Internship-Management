from django.contrib import admin

from .models import Message, MessageThread


@admin.register(MessageThread)
class MessageThreadAdmin(admin.ModelAdmin):
    list_display = ["id", "internship", "created_at"]
    raw_id_fields = ["internship"]
    readonly_fields = ["created_at", "updated_at"]


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ["id", "thread", "sender", "is_read", "created_at"]
    list_filter = ["is_read"]
    search_fields = ["body", "sender__email"]
    raw_id_fields = ["thread", "sender"]
    readonly_fields = ["created_at", "updated_at"]
