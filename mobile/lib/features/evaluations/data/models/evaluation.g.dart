// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evaluation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Criterion _$CriterionFromJson(Map<String, dynamic> json) => Criterion(
  key: json['key'] as String,
  label: json['label'] as String,
  min: (json['min'] as num).toInt(),
  max: (json['max'] as num).toInt(),
);

Map<String, dynamic> _$CriterionToJson(Criterion instance) => <String, dynamic>{
  'key': instance.key,
  'label': instance.label,
  'min': instance.min,
  'max': instance.max,
};

EvaluationUser _$EvaluationUserFromJson(Map<String, dynamic> json) =>
    EvaluationUser(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
    );

Map<String, dynamic> _$EvaluationUserToJson(EvaluationUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
    };

Evaluation _$EvaluationFromJson(Map<String, dynamic> json) => Evaluation(
  id: (json['id'] as num).toInt(),
  internship: (json['internship'] as num).toInt(),
  evaluator: EvaluationUser.fromJson(json['evaluator'] as Map<String, dynamic>),
  evaluatorType: json['evaluator_type'] as String,
  scores: json['scores'] as Map<String, dynamic>,
  comment: json['comment'] as String,
  totalScore: (json['total_score'] as num).toDouble(),
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$EvaluationToJson(Evaluation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'internship': instance.internship,
      'evaluator': instance.evaluator,
      'evaluator_type': instance.evaluatorType,
      'scores': instance.scores,
      'comment': instance.comment,
      'total_score': instance.totalScore,
      'created_at': instance.createdAt,
    };

EvaluationSummaryEntry _$EvaluationSummaryEntryFromJson(
  Map<String, dynamic> json,
) => EvaluationSummaryEntry(
  totalScore: (json['total_score'] as num).toDouble(),
  scores: json['scores'] as Map<String, dynamic>,
  comment: json['comment'] as String?,
);

Map<String, dynamic> _$EvaluationSummaryEntryToJson(
  EvaluationSummaryEntry instance,
) => <String, dynamic>{
  'total_score': instance.totalScore,
  'scores': instance.scores,
  'comment': instance.comment,
};

EvaluationSummary _$EvaluationSummaryFromJson(Map<String, dynamic> json) =>
    EvaluationSummary(
      company: json['company'] == null
          ? null
          : EvaluationSummaryEntry.fromJson(
              json['company'] as Map<String, dynamic>,
            ),
      teacher: json['teacher'] == null
          ? null
          : EvaluationSummaryEntry.fromJson(
              json['teacher'] as Map<String, dynamic>,
            ),
      student: json['student'] == null
          ? null
          : EvaluationSummaryEntry.fromJson(
              json['student'] as Map<String, dynamic>,
            ),
      combined: (json['combined'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$EvaluationSummaryToJson(EvaluationSummary instance) =>
    <String, dynamic>{
      'company': instance.company,
      'teacher': instance.teacher,
      'student': instance.student,
      'combined': instance.combined,
    };

EvaluationsPayload _$EvaluationsPayloadFromJson(Map<String, dynamic> json) =>
    EvaluationsPayload(
      criteria: EvaluationsPayload._criteriaFromJson(
        json['criteria'] as Map<String, dynamic>,
      ),
      evaluations: (json['evaluations'] as List<dynamic>)
          .map((e) => Evaluation.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: EvaluationSummary.fromJson(
        json['summary'] as Map<String, dynamic>,
      ),
    );
