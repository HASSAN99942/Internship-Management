"""Validation & representation for evaluations.

Writes happen in services.py; these serializers validate input and shape output.
"""

from rest_framework import serializers

from .constants import CRITERIA_BY_TYPE, SCORE_MAX, SCORE_MIN
from .models import Evaluation


class EvaluatorSummarySerializer(serializers.Serializer):
    id = serializers.IntegerField()
    email = serializers.EmailField()
    first_name = serializers.CharField()
    last_name = serializers.CharField()


class EvaluationReadSerializer(serializers.ModelSerializer):
    evaluator = EvaluatorSummarySerializer(read_only=True)

    class Meta:
        model = Evaluation
        fields = [
            "id",
            "internship",
            "evaluator",
            "evaluator_type",
            "scores",
            "comment",
            "total_score",
            "created_at",
        ]
        read_only_fields = fields


class SubmitEvaluationSerializer(serializers.Serializer):
    """Validates a submission against the criteria for ``evaluator_type``.

    ``evaluator_type`` is provided by the view (inferred from the caller's role).
    """

    scores = serializers.DictField(child=serializers.IntegerField())
    comment = serializers.CharField(required=False, allow_blank=True, default="")

    def __init__(self, *args, evaluator_type: str | None = None, **kwargs):
        self.evaluator_type = evaluator_type
        super().__init__(*args, **kwargs)

    def validate_scores(self, value: dict) -> dict:
        expected = {c["key"] for c in CRITERIA_BY_TYPE[self.evaluator_type]}
        provided = set(value.keys())
        if provided != expected:
            missing = expected - provided
            unknown = provided - expected
            problems = []
            if missing:
                problems.append(f"missing: {', '.join(sorted(missing))}")
            if unknown:
                problems.append(f"unknown: {', '.join(sorted(unknown))}")
            raise serializers.ValidationError(
                f"Scores must cover exactly the criteria ({'; '.join(problems)})."
            )
        for key, score in value.items():
            if not (SCORE_MIN <= score <= SCORE_MAX):
                raise serializers.ValidationError(
                    f"'{key}' must be between {SCORE_MIN} and {SCORE_MAX}."
                )
        return value


# --------------------------------------------------------------------------- #
# Aggregate payload for GET /internships/{id}/evaluations/
# --------------------------------------------------------------------------- #
class CriterionSerializer(serializers.Serializer):
    key = serializers.CharField()
    label = serializers.CharField()
    min = serializers.IntegerField()
    max = serializers.IntegerField()


class EvaluationsPayloadSerializer(serializers.Serializer):
    """Everything the internship detail needs to render the evaluation section."""

    criteria = serializers.DictField(child=CriterionSerializer(many=True))
    evaluations = EvaluationReadSerializer(many=True)
    summary = serializers.DictField()
