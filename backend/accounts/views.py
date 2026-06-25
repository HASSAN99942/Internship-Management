"""Thin HTTP layer: parse request -> call service/selector -> return response."""

from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView

from core.pagination import DefaultPagination

from . import selectors, services
from .models import User
from .permissions import (
    CanCancelSupervisionRequest,
    CanValidateSupervisionRequest,
    IsStudentOrTeacher,
    IsTeacherOrAdmin,
)
from .selectors import get_me
from .serializers import (
    AssignTeacherSerializer,
    CreateSupervisionRequestSerializer,
    CustomTokenObtainPairSerializer,
    MeSerializer,
    MeUpdateSerializer,
    RegisterSerializer,
    StudentRowSerializer,
    SupervisionRequestSerializer,
    TeacherOptionSerializer,
)


class RegisterView(APIView):
    """POST /api/v1/auth/register/ — public; creates user + role profile."""

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = services.register_user(**serializer.validated_data)
        return Response(
            MeSerializer(get_me(user)).data, status=status.HTTP_201_CREATED
        )


class LoginView(TokenObtainPairView):
    """POST /api/v1/auth/login/ — returns access + refresh (+ role)."""

    permission_classes = [AllowAny]
    serializer_class = CustomTokenObtainPairSerializer


class LogoutView(APIView):
    """POST /api/v1/auth/logout/ — blacklists the supplied refresh token."""

    permission_classes = [IsAuthenticated]

    def post(self, request):
        refresh = request.data.get("refresh")
        if not refresh:
            return Response(
                {"detail": "A refresh token is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            RefreshToken(refresh).blacklist()
        except TokenError:
            return Response(
                {"detail": "Invalid or expired refresh token."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return Response(status=status.HTTP_205_RESET_CONTENT)


class MeView(APIView):
    """GET/PATCH /api/v1/me/ — read or partially update the authenticated user."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(MeSerializer(get_me(request.user)).data)

    def patch(self, request):
        serializer = MeUpdateSerializer(
            data=request.data, partial=True, context={"request": request}
        )
        serializer.is_valid(raise_exception=True)
        user = services.update_me(user=request.user, **serializer.validated_data)
        return Response(MeSerializer(get_me(user)).data)


class TeacherListView(APIView):
    """GET /api/v1/teachers/ — teacher options for the supervisor picker.

    Authenticated only: it's used inside the app (student requesting a
    supervisor), not on the public signup page.
    """

    permission_classes = [IsAuthenticated]

    def get(self, request):
        teachers = selectors.list_teachers()
        return Response(TeacherOptionSerializer(teachers, many=True).data)


class StudentListView(APIView):
    """GET /api/v1/students/ — students for supervision (teacher/admin, scoped)."""

    permission_classes = [IsTeacherOrAdmin]

    def get(self, request):
        queryset = selectors.list_students_for(request.user)
        paginator = DefaultPagination()
        page = paginator.paginate_queryset(queryset, request, view=self)
        data = StudentRowSerializer(page, many=True).data
        return paginator.get_paginated_response(data)


class StudentAssignView(APIView):
    """PATCH /api/v1/students/{id}/ — set/clear a student's assigned teacher."""

    permission_classes = [IsTeacherOrAdmin]

    def patch(self, request, student_id):
        profile = selectors.get_student_profile(student_id)
        serializer = AssignTeacherSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        teacher_id = serializer.validated_data["assigned_teacher"]
        teacher = selectors.get_teacher(teacher_id) if teacher_id else None
        profile = services.assign_teacher(
            profile=profile, teacher_user=teacher, by_user=request.user
        )
        return Response(StudentRowSerializer(profile).data)


class SupervisionRequestListCreateView(APIView):
    """GET list (role-scoped) / POST create a supervision request."""

    def get_permissions(self):
        if self.request.method == "POST":
            return [IsStudentOrTeacher()]
        return [IsAuthenticated()]

    def get(self, request):
        requests = selectors.list_supervision_requests_for_user(request.user)
        return Response(SupervisionRequestSerializer(requests, many=True).data)

    def post(self, request):
        serializer = CreateSupervisionRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        target_id = serializer.validated_data["target_id"]

        if request.user.role == User.Role.STUDENT:
            teacher = selectors.get_teacher(target_id)
            req = services.request_supervision(
                student=request.user,
                teacher=teacher,
                initiated_by="student",
            )
        else:  # teacher (IsStudentOrTeacher restricts to student/teacher)
            student_profile = selectors.get_student_profile(target_id)
            req = services.request_supervision(
                student=student_profile.user,
                teacher=request.user,
                initiated_by="teacher",
            )
        return Response(
            SupervisionRequestSerializer(req).data, status=status.HTTP_201_CREATED
        )


class AcceptSupervisionRequestView(APIView):
    """POST /api/v1/supervision-requests/{id}/accept/ — counterparty only."""

    permission_classes = [IsAuthenticated, CanValidateSupervisionRequest]

    def post(self, request, pk):
        req = selectors.get_supervision_request(pk)
        self.check_object_permissions(request, req)
        services.accept_supervision_request(req=req)
        return Response(SupervisionRequestSerializer(req).data)


class RejectSupervisionRequestView(APIView):
    """POST /api/v1/supervision-requests/{id}/reject/ — counterparty only."""

    permission_classes = [IsAuthenticated, CanValidateSupervisionRequest]

    def post(self, request, pk):
        req = selectors.get_supervision_request(pk)
        self.check_object_permissions(request, req)
        services.reject_supervision_request(req=req)
        return Response(SupervisionRequestSerializer(req).data)


class CancelSupervisionRequestView(APIView):
    """POST /api/v1/supervision-requests/{id}/cancel/ — initiator only."""

    permission_classes = [IsAuthenticated, CanCancelSupervisionRequest]

    def post(self, request, pk):
        req = selectors.get_supervision_request(pk)
        self.check_object_permissions(request, req)
        services.cancel_supervision_request(req=req)
        return Response(SupervisionRequestSerializer(req).data)
