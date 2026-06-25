"""Thin HTTP layer: parse request -> call service/selector -> return response."""

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from core.pagination import DefaultPagination

from . import selectors, services
from .permissions import IsThreadParticipant
from .serializers import (
    MessageSerializer,
    SendMessageSerializer,
    ThreadDetailSerializer,
    ThreadListSerializer,
)


class ThreadListView(APIView):
    """GET /api/v1/threads/ — the caller's threads (unread counts + previews)."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        threads = selectors.list_threads_for_user(request.user)
        return Response(ThreadListSerializer(threads, many=True).data)


class ThreadDetailView(APIView):
    """GET /api/v1/threads/{id}/ — participants + internship reference."""

    permission_classes = [IsAuthenticated, IsThreadParticipant]

    def get(self, request, pk):
        thread = selectors.get_thread(pk)
        self.check_object_permissions(request, thread)
        return Response(
            ThreadDetailSerializer(selectors.thread_header(thread)).data
        )


class MessageListCreateView(APIView):
    """GET list (paginated) / POST send, within a thread."""

    permission_classes = [IsAuthenticated, IsThreadParticipant]

    def get(self, request, pk):
        thread = selectors.get_thread(pk)
        self.check_object_permissions(request, thread)
        messages = selectors.list_messages(thread)
        paginator = DefaultPagination()
        page = paginator.paginate_queryset(messages, request, view=self)
        data = MessageSerializer(page, many=True).data
        return paginator.get_paginated_response(data)

    def post(self, request, pk):
        thread = selectors.get_thread(pk)
        self.check_object_permissions(request, thread)
        serializer = SendMessageSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        message = services.send_message(
            thread=thread,
            sender=request.user,
            body=serializer.validated_data["body"],
        )
        return Response(
            MessageSerializer(message).data, status=status.HTTP_201_CREATED
        )


class MarkThreadReadView(APIView):
    """POST /api/v1/threads/{id}/read/ — mark the thread read for the caller."""

    permission_classes = [IsAuthenticated, IsThreadParticipant]

    def post(self, request, pk):
        thread = selectors.get_thread(pk)
        self.check_object_permissions(request, thread)
        updated = services.mark_thread_read(thread=thread, user=request.user)
        return Response({"marked_read": updated})
