"""Thin HTTP layer: parse request -> call service/selector -> return response."""

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from core.pagination import DefaultPagination
from core.permissions import IsStudent
from offers.selectors import get_offer

from . import selectors, services
from .models import Application
from .permissions import (
    CanViewApplication,
    IsApplicationStudentOwner,
    IsOfferOwnerForApplication,
)
from .serializers import ApplicationReadSerializer, ApplyWriteSerializer


class ApplyView(APIView):
    """POST /api/v1/offers/{id}/apply/ — student applies to a published offer."""

    permission_classes = [IsStudent]

    def post(self, request, offer_id):
        offer = get_offer(offer_id)
        serializer = ApplyWriteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        application = services.apply_to_offer(
            student=request.user, offer=offer, data=serializer.validated_data
        )
        return Response(
            ApplicationReadSerializer(
                application, context={"request": request}
            ).data,
            status=status.HTTP_201_CREATED,
        )


class ApplicationListView(APIView):
    """GET /api/v1/applications/ — role-scoped: student=own, company=received."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if user.role == "student":
            queryset = selectors.list_my_applications(user)
        elif user.role == "company":
            queryset = selectors.list_offer_applications(user)
        elif user.role == "admin":
            queryset = Application.objects.select_related(
                "offer", "student", "offer__company"
            ).order_by("-created_at")
        else:
            queryset = Application.objects.none()

        paginator = DefaultPagination()
        page = paginator.paginate_queryset(queryset, request, view=self)
        data = ApplicationReadSerializer(
            page, many=True, context={"request": request}
        ).data
        return paginator.get_paginated_response(data)


class ApplicationDetailView(APIView):
    """GET /api/v1/applications/{id}/ — party-scoped detail."""

    permission_classes = [IsAuthenticated, CanViewApplication]

    def get(self, request, pk):
        application = selectors.get_application(pk)
        self.check_object_permissions(request, application)
        return Response(ApplicationReadSerializer(application, context={"request": request}).data)


class AcceptApplicationView(APIView):
    """POST /api/v1/applications/{id}/accept/ — owning company (or admin)."""

    permission_classes = [IsAuthenticated, IsOfferOwnerForApplication]

    def post(self, request, pk):
        application = selectors.get_application(pk)
        self.check_object_permissions(request, application)
        services.accept_application(application=application)
        return Response(ApplicationReadSerializer(application, context={"request": request}).data)


class RejectApplicationView(APIView):
    """POST /api/v1/applications/{id}/reject/ — owning company (or admin)."""

    permission_classes = [IsAuthenticated, IsOfferOwnerForApplication]

    def post(self, request, pk):
        application = selectors.get_application(pk)
        self.check_object_permissions(request, application)
        services.reject_application(application=application)
        return Response(ApplicationReadSerializer(application, context={"request": request}).data)


class WithdrawApplicationView(APIView):
    """POST /api/v1/applications/{id}/withdraw/ — owning student, while pending."""

    permission_classes = [IsAuthenticated, IsApplicationStudentOwner]

    def post(self, request, pk):
        application = selectors.get_application(pk)
        self.check_object_permissions(request, application)
        services.withdraw_application(application=application, by_user=request.user)
        return Response(ApplicationReadSerializer(application, context={"request": request}).data)
