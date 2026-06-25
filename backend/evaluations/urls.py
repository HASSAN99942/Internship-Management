from django.urls import path

from .views import EvaluationDetailView, EvaluationListCreateView

urlpatterns = [
    path(
        "internships/<int:internship_id>/evaluations/",
        EvaluationListCreateView.as_view(),
        name="evaluation-list-create",
    ),
    path(
        "evaluations/<int:pk>/",
        EvaluationDetailView.as_view(),
        name="evaluation-detail",
    ),
]
