"""Business logic for offers — the only place that writes offer data."""

from django.db import transaction
from rest_framework.exceptions import ValidationError

from .models import Offer


@transaction.atomic
def create_offer(*, company_user, data: dict) -> Offer:
    """Create an offer for a company. Always starts as a draft."""
    return Offer.objects.create(
        company=company_user,
        status=Offer.Status.DRAFT,
        **data,
    )


@transaction.atomic
def update_offer(offer: Offer, data: dict) -> Offer:
    """Apply editable-field updates to an existing offer."""
    for field, value in data.items():
        setattr(offer, field, value)
    offer.save()
    return offer


@transaction.atomic
def publish_offer(offer: Offer) -> Offer:
    """Move a draft offer to published. Only valid from draft."""
    if offer.status != Offer.Status.DRAFT:
        raise ValidationError("Only draft offers can be published.")
    offer.status = Offer.Status.PUBLISHED
    offer.save(update_fields=["status", "updated_at"])
    return offer


@transaction.atomic
def close_offer(offer: Offer) -> Offer:
    """Close an offer (no longer open). Not valid if already closed."""
    if offer.status == Offer.Status.CLOSED:
        raise ValidationError("Offer is already closed.")
    offer.status = Offer.Status.CLOSED
    offer.save(update_fields=["status", "updated_at"])
    return offer


def delete_offer(offer: Offer) -> None:
    offer.delete()
