"""Thin HTTP layer for notifications."""

from django.shortcuts import get_object_or_404
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from core.pagination import DefaultPagination

from . import selectors, services
from .models import Notification
from .permissions import IsNotificationOwner
from .serializers import NotificationReadSerializer


class NotificationListView(APIView):
    """GET /api/v1/notifications/ — the caller's notifications (paginated)."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        queryset = selectors.list_notifications(request.user)
        paginator = DefaultPagination()
        page = paginator.paginate_queryset(queryset, request, view=self)
        data = NotificationReadSerializer(page, many=True).data
        return paginator.get_paginated_response(data)


class UnreadCountView(APIView):
    """GET /api/v1/notifications/unread-count/ — count for the topbar badge."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response({"unread": selectors.unread_count(request.user)})


class MarkReadView(APIView):
    """POST /api/v1/notifications/{id}/read/ — mark one read (owner only)."""

    permission_classes = [IsAuthenticated, IsNotificationOwner]

    def post(self, request, pk):
        notification = get_object_or_404(Notification, pk=pk)
        self.check_object_permissions(request, notification)
        services.mark_read(notification=notification, user=request.user)
        return Response(NotificationReadSerializer(notification).data)


class MarkAllReadView(APIView):
    """POST /api/v1/notifications/read-all/ — mark all the caller's read."""

    permission_classes = [IsAuthenticated]

    def post(self, request):
        count = services.mark_all_read(user=request.user)
        return Response({"marked_read": count})
