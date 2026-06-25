import 'package:json_annotation/json_annotation.dart';

part 'evaluation.g.dart';

@JsonSerializable()
class Criterion {
  const Criterion({
    required this.key,
    required this.label,
    required this.min,
    required this.max,
  });

  final String key;
  final String label;
  final int min;
  final int max;

  factory Criterion.fromJson(Map<String, dynamic> json) =>
      _$CriterionFromJson(json);
  Map<String, dynamic> toJson() => _$CriterionToJson(this);
}

@JsonSerializable()
class EvaluationUser {
  const EvaluationUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  final int id;
  final String email;
  @JsonKey(name: 'first_name')
  final String firstName;
  @JsonKey(name: 'last_name')
  final String lastName;

  String get fullName => '$firstName $lastName'.trim();

  factory EvaluationUser.fromJson(Map<String, dynamic> json) =>
      _$EvaluationUserFromJson(json);
  Map<String, dynamic> toJson() => _$EvaluationUserToJson(this);
}

@JsonSerializable()
class Evaluation {
  const Evaluation({
    required this.id,
    required this.internship,
    required this.evaluator,
    required this.evaluatorType,
    required this.scores,
    required this.comment,
    required this.totalScore,
    required this.createdAt,
  });

  final int id;
  final int internship;
  final EvaluationUser evaluator;
  @JsonKey(name: 'evaluator_type')
  final String evaluatorType;
  final Map<String, dynamic> scores;
  final String comment;
  @JsonKey(name: 'total_score')
  final double totalScore;
  @JsonKey(name: 'created_at')
  final String createdAt;

  int scoreFor(String key) {
    final v = scores[key];
    if (v == null) return 0;
    return (v as num).toInt();
  }

  factory Evaluation.fromJson(Map<String, dynamic> json) =>
      _$EvaluationFromJson(json);
  Map<String, dynamic> toJson() => _$EvaluationToJson(this);
}

@JsonSerializable()
class EvaluationSummaryEntry {
  const EvaluationSummaryEntry({
    required this.totalScore,
    required this.scores,
    this.comment,
  });

  @JsonKey(name: 'total_score')
  final double totalScore;
  final Map<String, dynamic> scores;
  final String? comment;

  int scoreFor(String key) {
    final v = scores[key];
    if (v == null) return 0;
    return (v as num).toInt();
  }

  factory EvaluationSummaryEntry.fromJson(Map<String, dynamic> json) =>
      _$EvaluationSummaryEntryFromJson(json);
  Map<String, dynamic> toJson() => _$EvaluationSummaryEntryToJson(this);
}

@JsonSerializable()
class EvaluationSummary {
  const EvaluationSummary({
    this.company,
    this.teacher,
    this.student,
    this.combined,
  });

  final EvaluationSummaryEntry? company;
  final EvaluationSummaryEntry? teacher;
  final EvaluationSummaryEntry? student;
  final double? combined;

  factory EvaluationSummary.fromJson(Map<String, dynamic> json) =>
      _$EvaluationSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$EvaluationSummaryToJson(this);
}

@JsonSerializable(createToJson: false)
class EvaluationsPayload {
  const EvaluationsPayload({
    required this.criteria,
    required this.evaluations,
    required this.summary,
  });

  // criteria is a map from evaluator_type -> list of criterion dicts.
  // We deserialize it manually below.
  @JsonKey(fromJson: _criteriaFromJson)
  final Map<String, List<Criterion>> criteria;
  final List<Evaluation> evaluations;
  final EvaluationSummary summary;

  static Map<String, List<Criterion>> _criteriaFromJson(
      Map<String, dynamic> json) {
    return json.map(
      (k, v) => MapEntry(
        k,
        (v as List)
            .map((e) => Criterion.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }

  List<Criterion> criteriaFor(String evaluatorType) =>
      criteria[evaluatorType] ?? [];

  Evaluation? evaluationFor(String evaluatorType) {
    try {
      return evaluations.firstWhere((e) => e.evaluatorType == evaluatorType);
    } catch (_) {
      return null;
    }
  }

  factory EvaluationsPayload.fromJson(Map<String, dynamic> json) =>
      _$EvaluationsPayloadFromJson(json);
}
