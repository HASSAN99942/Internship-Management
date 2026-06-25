from django.contrib import admin

from .models import Offer


@admin.register(Offer)
class OfferAdmin(admin.ModelAdmin):
    list_display = ["title", "company", "status", "location", "duration_weeks", "created_at"]
    list_filter = ["status", "location"]
    search_fields = ["title", "description", "skills", "company__email"]
    raw_id_fields = ["company"]
    readonly_fields = ["created_at", "updated_at"]
