from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    AcceptSupervisionRequestView,
    CancelSupervisionRequestView,
    LoginView,
    LogoutView,
    MeView,
    RegisterView,
    RejectSupervisionRequestView,
    StudentAssignView,
    StudentListView,
    SupervisionRequestListCreateView,
    TeacherListView,
)

urlpatterns = [
    path("auth/register/", RegisterView.as_view(), name="register"),
    path("auth/login/", LoginView.as_view(), name="login"),
    path("auth/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("auth/logout/", LogoutView.as_view(), name="logout"),
    path("me/", MeView.as_view(), name="me"),
    path("teachers/", TeacherListView.as_view(), name="teacher-list"),
    path("students/", StudentListView.as_view(), name="student-list"),
    path(
        "students/<int:student_id>/",
        StudentAssignView.as_view(),
        name="student-assign",
    ),
    path(
        "supervision-requests/",
        SupervisionRequestListCreateView.as_view(),
        name="supervision-request-list-create",
    ),
    path(
        "supervision-requests/<int:pk>/accept/",
        AcceptSupervisionRequestView.as_view(),
        name="supervision-request-accept",
    ),
    path(
        "supervision-requests/<int:pk>/reject/",
        RejectSupervisionRequestView.as_view(),
        name="supervision-request-reject",
    ),
    path(
        "supervision-requests/<int:pk>/cancel/",
        CancelSupervisionRequestView.as_view(),
        name="supervision-request-cancel",
    ),
]
