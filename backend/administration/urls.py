from django.urls import path

from .views import AdminStatsView, AssignTeacherView

urlpatterns = [
    path("admin/stats/", AdminStatsView.as_view(), name="admin-stats"),
    path(
        "admin/assign-teacher/",
        AssignTeacherView.as_view(),
        name="admin-assign-teacher",
    ),
]
