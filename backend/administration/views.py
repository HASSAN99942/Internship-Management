"""Admin-only oversight endpoints (thin)."""

from django.shortcuts import get_object_or_404
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.models import StudentProfile, User
from accounts.services import assign_teacher
from core.permissions import IsAdmin

from .selectors import get_stats
from .serializers import AssignTeacherSerializer


class AdminStatsView(APIView):
    """GET /api/v1/admin/stats/ — platform counts (ADMIN-04)."""

    permission_classes = [IsAdmin]

    def get(self, request):
        return Response(get_stats())


class AssignTeacherView(APIView):
    """POST /api/v1/admin/assign-teacher/ — set/clear a student's supervisor."""

    permission_classes = [IsAdmin]

    def post(self, request):
        serializer = AssignTeacherSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        student_id = serializer.validated_data["student_id"]
        teacher_id = serializer.validated_data["teacher_id"]

        profile = get_object_or_404(StudentProfile, user_id=student_id)
        teacher = (
            get_object_or_404(User, pk=teacher_id) if teacher_id is not None else None
        )
        # Role validation (teacher must be a teacher) lives in the service.
        assign_teacher(
            profile=profile, teacher_user=teacher, by_user=request.user
        )
        return Response(
            {
                "student_id": student_id,
                "assigned_teacher": profile.assigned_teacher_id,
            }
        )
