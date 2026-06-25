"""Thin HTTP layer: parse request -> call service/selector -> return response."""

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from internships.selectors import get_internship

from . import selectors, services
from .permissions import CanSubmitEvaluation, CanViewEvaluations
from .serializers import (
    EvaluationReadSerializer,
    EvaluationsPayloadSerializer,
    SubmitEvaluationSerializer,
)


class EvaluationListCreateView(APIView):
    """GET evaluations + summary + criteria / POST submit, for an internship."""

    def get_permissions(self):
        if self.request.method == "POST":
            return [IsAuthenticated(), CanSubmitEvaluation()]
        return [IsAuthenticated(), CanViewEvaluations()]

    def get(self, request, internship_id):
        internship = get_internship(internship_id)
        self.check_object_permissions(request, internship)
        payload = selectors.get_evaluations_payload(internship)
        return Response(
            EvaluationsPayloadSerializer(
                payload, context={"request": request}
            ).data
        )

    def post(self, request, internship_id):
        internship = get_internship(internship_id)
        self.check_object_permissions(request, internship)
        evaluator_type = request.user.role  # company | teacher | student
        serializer = SubmitEvaluationSerializer(
            data=request.data, evaluator_type=evaluator_type
        )
        serializer.is_valid(raise_exception=True)
        evaluation = services.submit_evaluation(
            internship=internship,
            evaluator=request.user,
            evaluator_type=evaluator_type,
            scores=serializer.validated_data["scores"],
            comment=serializer.validated_data.get("comment", ""),
        )
        return Response(
            EvaluationReadSerializer(evaluation).data,
            status=status.HTTP_201_CREATED,
        )


class EvaluationDetailView(APIView):
    """GET /api/v1/evaluations/{id}/ — read-only detail (parties + admin)."""

    permission_classes = [IsAuthenticated, CanViewEvaluations]

    def get(self, request, pk):
        evaluation = selectors.get_evaluation(pk)
        self.check_object_permissions(request, evaluation)
        return Response(EvaluationReadSerializer(evaluation).data)
