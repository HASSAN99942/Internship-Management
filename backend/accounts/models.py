from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.db import models

from core.models import TimeStampedModel

from .managers import UserManager


class User(AbstractBaseUser, PermissionsMixin):
    """Custom user: email is the login identifier; role drives authorization.

    Role-specific data lives in the one-to-one profile models below (SRS §7).
    """

    class Role(models.TextChoices):
        STUDENT = "student", "Student"
        COMPANY = "company", "Company"
        TEACHER = "teacher", "Teacher"
        ADMIN = "admin", "Admin"

    email = models.EmailField(unique=True)
    first_name = models.CharField(max_length=150, blank=True)
    last_name = models.CharField(max_length=150, blank=True)
    role = models.CharField(max_length=20, choices=Role.choices)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    date_joined = models.DateTimeField(auto_now_add=True)

    objects = UserManager()

    USERNAME_FIELD = "email"
    # email + password are always required; role is set explicitly on creation.
    REQUIRED_FIELDS: list[str] = []

    class Meta:
        ordering = ["email"]

    def __str__(self) -> str:
        return f"{self.email} ({self.role})"

    @property
    def full_name(self) -> str:
        return f"{self.first_name} {self.last_name}".strip()


class StudentProfile(TimeStampedModel):
    user = models.OneToOneField(
        User, on_delete=models.CASCADE, related_name="student_profile"
    )
    school = models.CharField(max_length=255)
    program = models.CharField(max_length=255)
    level = models.CharField(max_length=100)
    phone = models.CharField(max_length=30, blank=True)
    cv_file = models.FileField(upload_to="cvs/", blank=True, null=True)
    assigned_teacher = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="supervised_students",
        limit_choices_to={"role": User.Role.TEACHER},
    )

    def __str__(self) -> str:
        return f"StudentProfile<{self.user.email}>"


class CompanyProfile(TimeStampedModel):
    user = models.OneToOneField(
        User, on_delete=models.CASCADE, related_name="company_profile"
    )
    company_name = models.CharField(max_length=255)
    sector = models.CharField(max_length=255, blank=True)
    website = models.URLField(blank=True)
    address = models.CharField(max_length=255, blank=True)
    description = models.TextField(blank=True)
    contact_phone = models.CharField(max_length=30, blank=True)

    def __str__(self) -> str:
        return f"CompanyProfile<{self.company_name}>"


class TeacherProfile(TimeStampedModel):
    user = models.OneToOneField(
        User, on_delete=models.CASCADE, related_name="teacher_profile"
    )
    department = models.CharField(max_length=255)
    title = models.CharField(max_length=100, blank=True)
    phone = models.CharField(max_length=30, blank=True)

    def __str__(self) -> str:
        return f"TeacherProfile<{self.user.email}>"


class SupervisionRequest(TimeStampedModel):
    """A request to establish academic supervision between a student and teacher.

    Either party may initiate; the *other* party validates (accept/reject), and
    the initiator may cancel while pending. On acceptance the student's
    ``StudentProfile.assigned_teacher`` is set.
    """

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        ACCEPTED = "accepted", "Accepted"
        REJECTED = "rejected", "Rejected"
        CANCELLED = "cancelled", "Cancelled"

    class Initiator(models.TextChoices):
        STUDENT = "student", "Student"
        TEACHER = "teacher", "Teacher"

    student = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="supervision_requests_as_student",
        limit_choices_to={"role": User.Role.STUDENT},
    )
    teacher = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="supervision_requests_as_teacher",
        limit_choices_to={"role": User.Role.TEACHER},
    )
    initiated_by = models.CharField(max_length=10, choices=Initiator.choices)
    status = models.CharField(
        max_length=10, choices=Status.choices, default=Status.PENDING
    )
    decided_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["student", "teacher"],
                condition=models.Q(status="pending"),
                name="unique_pending_supervision_request",
            )
        ]
        indexes = [
            models.Index(fields=["status"]),
            models.Index(fields=["student"]),
            models.Index(fields=["teacher"]),
        ]

    def __str__(self) -> str:
        return (
            f"SupervisionRequest<{self.student_id}->{self.teacher_id} "
            f"({self.status})>"
        )
