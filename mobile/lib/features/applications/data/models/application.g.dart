// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfferSummary _$OfferSummaryFromJson(Map<String, dynamic> json) => OfferSummary(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
);

Map<String, dynamic> _$OfferSummaryToJson(OfferSummary instance) =>
    <String, dynamic>{'id': instance.id, 'title': instance.title};

ApplicantSummary _$ApplicantSummaryFromJson(Map<String, dynamic> json) =>
    ApplicantSummary(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
    );

Map<String, dynamic> _$ApplicantSummaryToJson(ApplicantSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
    };

Application _$ApplicationFromJson(Map<String, dynamic> json) => Application(
  id: (json['id'] as num).toInt(),
  offer: OfferSummary.fromJson(json['offer'] as Map<String, dynamic>),
  student: ApplicantSummary.fromJson(json['student'] as Map<String, dynamic>),
  coverMessage: json['cover_message'] as String,
  cvFile: json['cv_file'] as String?,
  status: json['status'] as String,
  decidedAt: json['decided_at'] as String?,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$ApplicationToJson(Application instance) =>
    <String, dynamic>{
      'id': instance.id,
      'offer': instance.offer,
      'student': instance.student,
      'cover_message': instance.coverMessage,
      'cv_file': instance.cvFile,
      'status': instance.status,
      'decided_at': instance.decidedAt,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

PaginatedApplications _$PaginatedApplicationsFromJson(
  Map<String, dynamic> json,
) => PaginatedApplications(
  count: (json['count'] as num).toInt(),
  next: json['next'] as String?,
  previous: json['previous'] as String?,
  results: (json['results'] as List<dynamic>)
      .map((e) => Application.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PaginatedApplicationsToJson(
  PaginatedApplications instance,
) => <String, dynamic>{
  'count': instance.count,
  'next': instance.next,
  'previous': instance.previous,
  'results': instance.results,
};
