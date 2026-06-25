"""Thin HTTP layer: parse request -> call service/selector -> return response."""

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from core.pagination import DefaultPagination

from . import selectors, services
from .permissions import (
    CanValidateInternship,
    CanViewInternship,
    IsInternshipParty,
    IsInternshipStudent,
    IsInternshipSupervisor,
    IsTaskOwner,
)
from .serializers import (
    InternshipDashboardSerializer,
    InternshipReadSerializer,
    ReportReadSerializer,
    ReportSubmitSerializer,
    RequestChangesSerializer,
    TaskReadSerializer,
    TaskSubmitSerializer,
    TaskWriteSerializer,
)


class InternshipListView(APIView):
    """GET /api/v1/internships/ — internships visible to the caller (role-scoped)."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        queryset = selectors.list_internships_for_user(request.user)
        paginator = DefaultPagination()
        page = paginator.paginate_queryset(queryset, request, view=self)
        data = InternshipReadSerializer(page, many=True).data
        return paginator.get_paginated_response(data)


class InternshipDetailView(APIView):
    """GET /api/v1/internships/{id}/ — dashboard aggregate (parties/tasks/reports/progress)."""

    permission_classes = [IsAuthenticated, CanViewInternship]

    def get(self, request, pk):
        internship = selectors.get_internship(pk)
        self.check_object_permissions(request, internship)
        dashboard = selectors.get_internship_dashboard(internship)
        return Response(
            InternshipDashboardSerializer(
                dashboard, context={"request": request}
            ).data
        )


class ValidateInternshipView(APIView):
    """POST /api/v1/internships/{id}/validate/ — assigned teacher or admin."""

    permission_classes = [IsAuthenticated, CanValidateInternship]

    def post(self, request, pk):
        internship = selectors.get_internship(pk)
        self.check_object_permissions(request, internship)
        services.validate_internship(internship=internship, by_user=request.user)
        return Response(InternshipReadSerializer(internship).data)


# --------------------------------------------------------------------------- #
# Tasks
# --------------------------------------------------------------------------- #
class TaskListCreateView(APIView):
    """GET list (parties) / POST create (supervisor) under an internship."""

    permission_classes = [IsAuthenticated]

    def get(self, request, internship_id):
        internship = selectors.get_internship(internship_id)
        if not IsInternshipParty().has_object_permission(request, self, internship):
            self.permission_denied(request, message=IsInternshipParty.message)
        data = TaskReadSerializer(
            selectors.list_tasks(internship), many=True, context={"request": request}
        ).data
        return Response(data)

    def post(self, request, internship_id):
        internship = selectors.get_internship(internship_id)
        if not IsInternshipSupervisor().has_object_permission(
            request, self, internship
        ):
            self.permission_denied(request, message=IsInternshipSupervisor.message)
        serializer = TaskWriteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        task = services.create_task(
            internship=internship,
            by_user=request.user,
            data=serializer.validated_data,
        )
        return Response(
            TaskReadSerializer(task, context={"request": request}).data,
            status=status.HTTP_201_CREATED,
        )


class TaskDetailView(APIView):
    """GET detail (parties) / PATCH generic update (task owner)."""

    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        task = selectors.get_task(pk)
        if not IsInternshipParty().has_object_permission(request, self, task):
            self.permission_denied(request, message=IsInternshipParty.message)
        return Response(TaskReadSerializer(task, context={"request": request}).data)

    def patch(self, request, pk):
        task = selectors.get_task(pk)
        if not IsTaskOwner().has_object_permission(request, self, task):
            self.permission_denied(request, message=IsTaskOwner.message)
        serializer = TaskWriteSerializer(data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        task = services.update_task(task=task, data=serializer.validated_data)
        return Response(TaskReadSerializer(task, context={"request": request}).data)


class TaskSubmitView(APIView):
    """POST /api/v1/tasks/{id}/submit/ — the internship's student."""

    permission_classes = [IsAuthenticated, IsInternshipStudent]

    def post(self, request, pk):
        task = selectors.get_task(pk)
        self.check_object_permissions(request, task)
        serializer = TaskSubmitSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        services.submit_task(
            task=task,
            note=serializer.validated_data.get("submission_note", ""),
            file=serializer.validated_data.get("submission_file"),
        )
        return Response(TaskReadSerializer(task, context={"request": request}).data)


class TaskValidateView(APIView):
    """POST /api/v1/tasks/{id}/validate/ — company or assigned teacher."""

    permission_classes = [IsAuthenticated, IsInternshipSupervisor]

    def post(self, request, pk):
        task = selectors.get_task(pk)
        self.check_object_permissions(request, task)
        services.validate_task(task=task)
        return Response(TaskReadSerializer(task, context={"request": request}).data)


class TaskRequestChangesView(APIView):
    """POST /api/v1/tasks/{id}/request-changes/ — company or assigned teacher."""

    permission_classes = [IsAuthenticated, IsInternshipSupervisor]

    def post(self, request, pk):
        task = selectors.get_task(pk)
        self.check_object_permissions(request, task)
        services.request_task_changes(task=task)
        return Response(TaskReadSerializer(task, context={"request": request}).data)


# --------------------------------------------------------------------------- #
# Reports
# --------------------------------------------------------------------------- #
class ReportListCreateView(APIView):
    """GET list (parties) / POST submit (student) under an internship."""

    permission_classes = [IsAuthenticated]

    def get(self, request, internship_id):
        internship = selectors.get_internship(internship_id)
        if not IsInternshipParty().has_object_permission(request, self, internship):
            self.permission_denied(request, message=IsInternshipParty.message)
        data = ReportReadSerializer(
            selectors.list_reports(internship),
            many=True,
            context={"request": request},
        ).data
        return Response(data)

    def post(self, request, internship_id):
        internship = selectors.get_internship(internship_id)
        if not IsInternshipStudent().has_object_permission(
            request, self, internship
        ):
            self.permission_denied(request, message=IsInternshipStudent.message)
        serializer = ReportSubmitSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        report = services.submit_report(
            internship=internship,
            by_student=request.user,
            data=serializer.validated_data,
        )
        return Response(
            ReportReadSerializer(report, context={"request": request}).data,
            status=status.HTTP_201_CREATED,
        )


class ReportDetailView(APIView):
    """GET /api/v1/reports/{id}/ — parties only."""

    permission_classes = [IsAuthenticated, IsInternshipParty]

    def get(self, request, pk):
        report = selectors.get_report(pk)
        self.check_object_permissions(request, report)
        return Response(
            ReportReadSerializer(report, context={"request": request}).data
        )


class ReportValidateView(APIView):
    """POST /api/v1/reports/{id}/validate/ — company or assigned teacher."""

    permission_classes = [IsAuthenticated, IsInternshipSupervisor]

    def post(self, request, pk):
        report = selectors.get_report(pk)
        self.check_object_permissions(request, report)
        services.validate_report(report=report)
        return Response(
            ReportReadSerializer(report, context={"request": request}).data
        )


class ReportRequestChangesView(APIView):
    """POST /api/v1/reports/{id}/request-changes/ — supervisor, with feedback."""

    permission_classes = [IsAuthenticated, IsInternshipSupervisor]

    def post(self, request, pk):
        report = selectors.get_report(pk)
        self.check_object_permissions(request, report)
        serializer = RequestChangesSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        services.request_report_changes(
            report=report, feedback=serializer.validated_data["feedback"]
        )
        return Response(
            ReportReadSerializer(report, context={"request": request}).data
        )
