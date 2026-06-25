from django.urls import path

from .views import (
    MarkThreadReadView,
    MessageListCreateView,
    ThreadDetailView,
    ThreadListView,
)

urlpatterns = [
    path("threads/", ThreadListView.as_view(), name="thread-list"),
    path("threads/<int:pk>/", ThreadDetailView.as_view(), name="thread-detail"),
    path(
        "threads/<int:pk>/messages/",
        MessageListCreateView.as_view(),
        name="thread-messages",
    ),
    path(
        "threads/<int:pk>/read/",
        MarkThreadReadView.as_view(),
        name="thread-read",
    ),
]
