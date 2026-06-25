from django.urls import path

from .views import (
    OfferCloseView,
    OfferDetailView,
    OfferMineView,
    OfferPublishView,
    OffersView,
)

urlpatterns = [
    path("offers/", OffersView.as_view(), name="offer-list-create"),
    path("offers/mine/", OfferMineView.as_view(), name="offer-mine"),
    path("offers/<int:pk>/", OfferDetailView.as_view(), name="offer-detail"),
    path("offers/<int:pk>/publish/", OfferPublishView.as_view(), name="offer-publish"),
    path("offers/<int:pk>/close/", OfferCloseView.as_view(), name="offer-close"),
]
