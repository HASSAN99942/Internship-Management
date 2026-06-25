// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'internship.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PartySummary _$PartySummaryFromJson(Map<String, dynamic> json) => PartySummary(
  id: (json['id'] as num).toInt(),
  email: json['email'] as String,
  firstName: json['first_name'] as String,
  lastName: json['last_name'] as String,
);

Map<String, dynamic> _$PartySummaryToJson(PartySummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
    };

Internship _$InternshipFromJson(Map<String, dynamic> json) => Internship(
  id: (json['id'] as num).toInt(),
  application: (json['application'] as num).toInt(),
  offerTitle: json['offer_title'] as String,
  student: PartySummary.fromJson(json['student'] as Map<String, dynamic>),
  company: PartySummary.fromJson(json['company'] as Map<String, dynamic>),
  teacher: json['teacher'] == null
      ? null
      : PartySummary.fromJson(json['teacher'] as Map<String, dynamic>),
  status: json['status'] as String,
  startDate: json['start_date'] as String,
  endDate: json['end_date'] as String,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$InternshipToJson(Internship instance) =>
    <String, dynamic>{
      'id': instance.id,
      'application': instance.application,
      'offer_title': instance.offerTitle,
      'student': instance.student,
      'company': instance.company,
      'teacher': instance.teacher,
      'status': instance.status,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

PaginatedInternships _$PaginatedInternshipsFromJson(
  Map<String, dynamic> json,
) => PaginatedInternships(
  count: (json['count'] as num).toInt(),
  next: json['next'] as String?,
  previous: json['previous'] as String?,
  results: (json['results'] as List<dynamic>)
      .map((e) => Internship.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PaginatedInternshipsToJson(
  PaginatedInternships instance,
) => <String, dynamic>{
  'count': instance.count,
  'next': instance.next,
  'previous': instance.previous,
  'results': instance.results,
};

InternshipProgress _$InternshipProgressFromJson(Map<String, dynamic> json) =>
    InternshipProgress(
      tasksTotal: (json['tasks_total'] as num).toInt(),
      tasksValidated: (json['tasks_validated'] as num).toInt(),
      tasksValidatedPct: (json['tasks_validated_pct'] as num).toInt(),
      reportsTotal: (json['reports_total'] as num).toInt(),
      reportsValidated: (json['reports_validated'] as num).toInt(),
      reportsValidatedPct: (json['reports_validated_pct'] as num).toInt(),
    );

Map<String, dynamic> _$InternshipProgressToJson(InternshipProgress instance) =>
    <String, dynamic>{
      'tasks_total': instance.tasksTotal,
      'tasks_validated': instance.tasksValidated,
      'tasks_validated_pct': instance.tasksValidatedPct,
      'reports_total': instance.reportsTotal,
      'reports_validated': instance.reportsValidated,
      'reports_validated_pct': instance.reportsValidatedPct,
    };
