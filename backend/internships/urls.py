from django.urls import path

from .views import (
    InternshipDetailView,
    InternshipListView,
    ReportDetailView,
    ReportListCreateView,
    ReportRequestChangesView,
    ReportValidateView,
    TaskDetailView,
    TaskListCreateView,
    TaskRequestChangesView,
    TaskSubmitView,
    TaskValidateView,
    ValidateInternshipView,
)

urlpatterns = [
    path("internships/", InternshipListView.as_view(), name="internship-list"),
    path(
        "internships/<int:pk>/",
        InternshipDetailView.as_view(),
        name="internship-detail",
    ),
    path(
        "internships/<int:pk>/validate/",
        ValidateInternshipView.as_view(),
        name="internship-validate",
    ),
    # Tasks
    path(
        "internships/<int:internship_id>/tasks/",
        TaskListCreateView.as_view(),
        name="task-list-create",
    ),
    path("tasks/<int:pk>/", TaskDetailView.as_view(), name="task-detail"),
    path("tasks/<int:pk>/submit/", TaskSubmitView.as_view(), name="task-submit"),
    path(
        "tasks/<int:pk>/validate/",
        TaskValidateView.as_view(),
        name="task-validate",
    ),
    path(
        "tasks/<int:pk>/request-changes/",
        TaskRequestChangesView.as_view(),
        name="task-request-changes",
    ),
    # Reports
    path(
        "internships/<int:internship_id>/reports/",
        ReportListCreateView.as_view(),
        name="report-list-create",
    ),
    path("reports/<int:pk>/", ReportDetailView.as_view(), name="report-detail"),
    path(
        "reports/<int:pk>/validate/",
        ReportValidateView.as_view(),
        name="report-validate",
    ),
    path(
        "reports/<int:pk>/request-changes/",
        ReportRequestChangesView.as_view(),
        name="report-request-changes",
    ),
]
