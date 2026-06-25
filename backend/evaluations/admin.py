from django.contrib import admin

from .models import Evaluation


@admin.register(Evaluation)
class EvaluationAdmin(admin.ModelAdmin):
    list_display = ["id", "internship", "evaluator_type", "evaluator", "total_score", "created_at"]
    list_filter = ["evaluator_type"]
    search_fields = ["internship__student__email", "evaluator__email"]
    raw_id_fields = ["internship", "evaluator"]
    readonly_fields = ["created_at", "updated_at"]
