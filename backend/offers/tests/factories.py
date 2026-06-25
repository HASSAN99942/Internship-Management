"""Shared helpers for offers tests."""

from datetime import date

from accounts.services import register_user
from offers.models import Offer

VALID_OFFER = {
    "title": "Backend Intern",
    "description": "Work on our Django API.",
    "skills": "python, django",
    "location": "Casablanca",
    "duration_weeks": 12,
    "start_date": "2026-09-01",
    "positions": 2,
}


def make_company(email="company@example.com", name="Acme"):
    return register_user(
        email=email,
        password="Str0ngPass!23",
        role="company",
        profile={"company_name": name},
    )


def make_student(email="student@example.com"):
    return register_user(
        email=email,
        password="Str0ngPass!23",
        role="student",
        profile={"school": "ENSA", "program": "SE", "level": "M1"},
    )


def make_teacher(email="teacher@example.com"):
    return register_user(
        email=email,
        password="Str0ngPass!23",
        role="teacher",
        profile={"department": "CS"},
    )


def make_offer(company, *, status=Offer.Status.DRAFT, **overrides):
    data = {
        "title": "Backend Intern",
        "description": "Work on our Django API.",
        "skills": "python, django",
        "location": "Casablanca",
        "duration_weeks": 12,
        "start_date": date(2026, 9, 1),
        "positions": 1,
    }
    data.update(overrides)
    return Offer.objects.create(company=company, status=status, **data)
