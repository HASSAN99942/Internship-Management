"""Thin HTTP layer: parse request -> call service/selector -> return response."""

from rest_framework import status
from rest_framework.generics import GenericAPIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from core.permissions import IsCompany

from . import services
from .permissions import CanViewOffer, IsOfferOwnerOrAdmin
from .selectors import get_offer, list_company_offers, list_published_offers
from .serializers import OfferReadSerializer, OfferWriteSerializer


class OffersView(GenericAPIView):
    """GET /api/v1/offers/  — list published (paginated, filtered).
    POST /api/v1/offers/ — create (company only)."""

    serializer_class = OfferReadSerializer

    def get_permissions(self):
        if self.request.method == "POST":
            return [IsAuthenticated(), IsCompany()]
        return [IsAuthenticated()]

    def get(self, request):
        queryset = list_published_offers(request.query_params)
        page = self.paginate_queryset(queryset)
        serializer = OfferReadSerializer(page, many=True)
        return self.get_paginated_response(serializer.data)

    def post(self, request):
        serializer = OfferWriteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        offer = services.create_offer(
            company_user=request.user, data=serializer.validated_data
        )
        return Response(
            OfferReadSerializer(offer).data, status=status.HTTP_201_CREATED
        )


class OfferMineView(GenericAPIView):
    """GET /api/v1/offers/mine/ — the company's own offers (all statuses)."""

    serializer_class = OfferReadSerializer
    permission_classes = [IsAuthenticated, IsCompany]

    def get(self, request):
        queryset = list_company_offers(request.user)
        page = self.paginate_queryset(queryset)
        serializer = OfferReadSerializer(page, many=True)
        return self.get_paginated_response(serializer.data)


class OfferDetailView(GenericAPIView):
    """GET (view) / PATCH (update) / DELETE on /api/v1/offers/{id}/."""

    serializer_class = OfferReadSerializer

    def get_permissions(self):
        if self.request.method in ("PATCH", "DELETE"):
            return [IsAuthenticated(), IsOfferOwnerOrAdmin()]
        return [IsAuthenticated(), CanViewOffer()]

    def get_object(self):
        offer = get_offer(self.kwargs["pk"])
        self.check_object_permissions(self.request, offer)
        return offer

    def get(self, request, pk):
        offer = self.get_object()
        return Response(OfferReadSerializer(offer).data)

    def patch(self, request, pk):
        offer = self.get_object()
        serializer = OfferWriteSerializer(offer, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        offer = services.update_offer(offer, serializer.validated_data)
        return Response(OfferReadSerializer(offer).data)

    def delete(self, request, pk):
        offer = self.get_object()
        services.delete_offer(offer)
        return Response(status=status.HTTP_204_NO_CONTENT)


class _OwnedOfferActionView(GenericAPIView):
    """Base for owner/admin-only POST actions on a single offer."""

    serializer_class = OfferReadSerializer
    permission_classes = [IsAuthenticated, IsOfferOwnerOrAdmin]

    def get_object(self):
        offer = get_offer(self.kwargs["pk"])
        self.check_object_permissions(self.request, offer)
        return offer


class OfferPublishView(_OwnedOfferActionView):
    """POST /api/v1/offers/{id}/publish/"""

    def post(self, request, pk):
        offer = services.publish_offer(self.get_object())
        return Response(OfferReadSerializer(offer).data)


class OfferCloseView(_OwnedOfferActionView):
    """POST /api/v1/offers/{id}/close/"""

    def post(self, request, pk):
        offer = services.close_offer(self.get_object())
        return Response(OfferReadSerializer(offer).data)
