from django.urls import path

from .views import (
    AcceptApplicationView,
    ApplicationDetailView,
    ApplicationListView,
    ApplyView,
    RejectApplicationView,
    WithdrawApplicationView,
)

urlpatterns = [
    path("offers/<int:offer_id>/apply/", ApplyView.as_view(), name="offer-apply"),
    path("applications/", ApplicationListView.as_view(), name="application-list"),
    path(
        "applications/<int:pk>/",
        ApplicationDetailView.as_view(),
        name="application-detail",
    ),
    path(
        "applications/<int:pk>/accept/",
        AcceptApplicationView.as_view(),
        name="application-accept",
    ),
    path(
        "applications/<int:pk>/reject/",
        RejectApplicationView.as_view(),
        name="application-reject",
    ),
    path(
        "applications/<int:pk>/withdraw/",
        WithdrawApplicationView.as_view(),
        name="application-withdraw",
    ),
]
