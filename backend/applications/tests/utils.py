"""Shared factory helpers for application/internship tests."""

import datetime

from accounts.services import register_user
from offers.services import create_offer, publish_offer

_counter = {"n": 0}


def _email(prefix: str) -> str:
    _counter["n"] += 1
    return f"{prefix}{_counter['n']}@example.com"


def make_student(**profile):
    data = {"school": "ENSA", "program": "SE", "level": "M1"}
    data.update(profile)
    return register_user(
        email=_email("stu"),
        password="Str0ngPass!23",
        role="student",
        profile=data,
    )


def make_company():
    return register_user(
        email=_email("co"),
        password="Str0ngPass!23",
        role="company",
        profile={"company_name": "Acme"},
    )


def make_teacher():
    return register_user(
        email=_email("teach"),
        password="Str0ngPass!23",
        role="teacher",
        profile={"department": "CS"},
    )


def make_draft_offer(company, **overrides):
    data = dict(
        title="Intern",
        description="d",
        skills="python",
        location="Rabat",
        duration_weeks=8,
        start_date=datetime.date(2026, 10, 1),
        positions=1,
    )
    data.update(overrides)
    return create_offer(company_user=company, data=data)


def make_published_offer(company, **overrides):
    return publish_offer(make_draft_offer(company, **overrides))
