"""Factory helpers for internship monitoring tests.

Builds on applications.tests.utils to create the full chain:
offer -> application -> accepted internship -> (optionally) active internship.
"""

from applications.models import Application
from applications.services import accept_application
from applications.tests.utils import (  # noqa: F401  (re-exported for tests)
    make_company,
    make_published_offer,
    make_student,
    make_teacher,
)
from internships.services import validate_internship


def make_pending_internship():
    """Create an internship in pending_academic_validation with a teacher.

    Returns (internship, student, company, teacher).
    """
    company = make_company()
    student = make_student()
    teacher = make_teacher()
    profile = student.student_profile
    profile.assigned_teacher = teacher
    profile.save()

    offer = make_published_offer(company, positions=3)
    Application.objects.create(
        offer=offer, student=student, cover_message="Hi"
    )
    application = Application.objects.get(offer=offer, student=student)
    internship = accept_application(application=application)
    return internship, student, company, teacher


def make_active_internship():
    """Create an active internship (teacher-validated). Returns the 4-tuple."""
    internship, student, company, teacher = make_pending_internship()
    validate_internship(internship=internship, by_user=teacher)
    internship.refresh_from_db()
    return internship, student, company, teacher
