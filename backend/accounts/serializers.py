"""Validation & representation for accounts.

Serializers here do not write to the database — that is the job of
``services.py``. Registration/update views validate with these serializers,
then call a service. Read serializers shape the response.
"""

from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from .models import (
    CompanyProfile,
    StudentProfile,
    SupervisionRequest,
    TeacherProfile,
    User,
)


# --------------------------------------------------------------------------- #
# Teacher reference (embedded where a student's supervisor is shown)
# --------------------------------------------------------------------------- #
class AssignedTeacherSerializer(serializers.Serializer):
    """Minimal teacher info embedded in a student row / profile."""

    id = serializers.IntegerField()
    email = serializers.EmailField()
    first_name = serializers.CharField()
    last_name = serializers.CharField()


# --------------------------------------------------------------------------- #
# Profile serializers — read (representation)
# --------------------------------------------------------------------------- #
class StudentProfileSerializer(serializers.ModelSerializer):
    assigned_teacher = AssignedTeacherSerializer(read_only=True)

    class Meta:
        model = StudentProfile
        fields = [
            "school",
            "program",
            "level",
            "phone",
            "cv_file",
            "assigned_teacher",
        ]


class CompanyProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = CompanyProfile
        fields = [
            "company_name",
            "sector",
            "website",
            "address",
            "description",
            "contact_phone",
        ]


class TeacherProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = TeacherProfile
        fields = ["department", "title", "phone"]


# --------------------------------------------------------------------------- #
# Profile serializers — write (validate role-specific required fields)
# --------------------------------------------------------------------------- #
class StudentProfileWriteSerializer(serializers.ModelSerializer):
    # Supervision is established post-registration via the supervision-request
    # flow (mutual consent), so the supervisor is not set at signup.
    class Meta:
        model = StudentProfile
        fields = ["school", "program", "level", "phone"]
        extra_kwargs = {
            "school": {"required": True},
            "program": {"required": True},
            "level": {"required": True},
            "phone": {"required": False},
        }


class CompanyProfileWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = CompanyProfile
        fields = [
            "company_name",
            "sector",
            "website",
            "address",
            "description",
            "contact_phone",
        ]
        extra_kwargs = {"company_name": {"required": True}}


class TeacherProfileWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = TeacherProfile
        fields = ["department", "title", "phone"]
        extra_kwargs = {"department": {"required": True}}


# Role -> write serializer used for both registration and profile updates.
PROFILE_WRITE_SERIALIZERS = {
    User.Role.STUDENT: StudentProfileWriteSerializer,
    User.Role.COMPANY: CompanyProfileWriteSerializer,
    User.Role.TEACHER: TeacherProfileWriteSerializer,
}


# --------------------------------------------------------------------------- #
# Registration
# --------------------------------------------------------------------------- #
class RegisterSerializer(serializers.Serializer):
    """Validates a registration request. Admin role is intentionally excluded."""

    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)
    first_name = serializers.CharField(
        max_length=150, required=False, allow_blank=True, default=""
    )
    last_name = serializers.CharField(
        max_length=150, required=False, allow_blank=True, default=""
    )
    role = serializers.ChoiceField(
        choices=[
            User.Role.STUDENT,
            User.Role.COMPANY,
            User.Role.TEACHER,
        ]
    )
    profile = serializers.DictField(required=False)

    def validate_email(self, value: str) -> str:
        value = value.lower()
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError(
                "A user with this email already exists."
            )
        return value

    def validate_password(self, value: str) -> str:
        validate_password(value)
        return value

    def validate(self, attrs):
        role = attrs["role"]
        profile_serializer = PROFILE_WRITE_SERIALIZERS[role](
            data=attrs.get("profile", {})
        )
        profile_serializer.is_valid(raise_exception=True)
        attrs["profile"] = profile_serializer.validated_data
        return attrs


# --------------------------------------------------------------------------- #
# Current user (/me)
# --------------------------------------------------------------------------- #
class MeSerializer(serializers.ModelSerializer):
    """Read representation of the authenticated user with its role profile."""

    profile = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            "id",
            "email",
            "first_name",
            "last_name",
            "role",
            "is_active",
            "date_joined",
            "profile",
        ]
        read_only_fields = fields

    def get_profile(self, user: User):
        if user.role == User.Role.STUDENT and hasattr(user, "student_profile"):
            return StudentProfileSerializer(user.student_profile).data
        if user.role == User.Role.COMPANY and hasattr(user, "company_profile"):
            return CompanyProfileSerializer(user.company_profile).data
        if user.role == User.Role.TEACHER and hasattr(user, "teacher_profile"):
            return TeacherProfileSerializer(user.teacher_profile).data
        return None


class MeUpdateSerializer(serializers.Serializer):
    """Validates a partial update to the authenticated user and its profile."""

    first_name = serializers.CharField(
        max_length=150, required=False, allow_blank=True
    )
    last_name = serializers.CharField(
        max_length=150, required=False, allow_blank=True
    )
    profile = serializers.DictField(required=False)

    def validate(self, attrs):
        profile_data = attrs.get("profile")
        if profile_data is not None:
            user = self.context["request"].user
            serializer_cls = PROFILE_WRITE_SERIALIZERS.get(user.role)
            if serializer_cls is None:
                raise serializers.ValidationError(
                    "This role has no editable profile."
                )
            profile_serializer = serializer_cls(data=profile_data, partial=True)
            profile_serializer.is_valid(raise_exception=True)
            attrs["profile"] = profile_serializer.validated_data
        return attrs


# --------------------------------------------------------------------------- #
# JWT login
# --------------------------------------------------------------------------- #
class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Adds the user's role to the token claims and the login response body."""

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token["role"] = user.role
        return token

    def validate(self, attrs):
        data = super().validate(attrs)
        data["role"] = self.user.role
        return data


# --------------------------------------------------------------------------- #
# Teacher options (student's supervisor picker)
# --------------------------------------------------------------------------- #
class TeacherOptionSerializer(serializers.ModelSerializer):
    """A selectable teacher for the student supervisor picker."""

    full_name = serializers.CharField(read_only=True)
    department = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ["id", "full_name", "email", "department"]
        read_only_fields = fields

    def get_department(self, obj: User) -> str:
        profile = getattr(obj, "teacher_profile", None)
        return profile.department if profile else ""


# --------------------------------------------------------------------------- #
# Student supervision (teacher "My students")
# --------------------------------------------------------------------------- #
class StudentRowSerializer(serializers.ModelSerializer):
    """A student profile row for the supervision list."""

    id = serializers.IntegerField(source="user.id", read_only=True)
    email = serializers.EmailField(source="user.email", read_only=True)
    first_name = serializers.CharField(source="user.first_name", read_only=True)
    last_name = serializers.CharField(source="user.last_name", read_only=True)
    assigned_teacher = AssignedTeacherSerializer(read_only=True)

    class Meta:
        model = StudentProfile
        fields = [
            "id",
            "email",
            "first_name",
            "last_name",
            "school",
            "program",
            "level",
            "assigned_teacher",
        ]
        read_only_fields = fields


class AssignTeacherSerializer(serializers.Serializer):
    """Input for PATCH /students/{id}/ — a teacher user id, or null to release."""

    assigned_teacher = serializers.IntegerField(allow_null=True)


# --------------------------------------------------------------------------- #
# Supervision requests (mutual-consent flow)
# --------------------------------------------------------------------------- #
class SupervisionPartySerializer(serializers.Serializer):
    """Minimal user info for a party to a supervision request."""

    id = serializers.IntegerField()
    email = serializers.EmailField()
    first_name = serializers.CharField()
    last_name = serializers.CharField()


class SupervisionRequestSerializer(serializers.ModelSerializer):
    student = SupervisionPartySerializer(read_only=True)
    teacher = SupervisionPartySerializer(read_only=True)

    class Meta:
        model = SupervisionRequest
        fields = [
            "id",
            "student",
            "teacher",
            "initiated_by",
            "status",
            "decided_at",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields


class CreateSupervisionRequestSerializer(serializers.Serializer):
    """Input for POST /supervision-requests/.

    ``target_id`` is the teacher's user id (student initiating) or the student's
    user id (teacher initiating); the view resolves it by the caller's role.
    """

    target_id = serializers.IntegerField()
