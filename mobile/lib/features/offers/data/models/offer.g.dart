// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompanySummary _$CompanySummaryFromJson(Map<String, dynamic> json) =>
    CompanySummary(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      companyName: json['company_name'] as String,
    );

Map<String, dynamic> _$CompanySummaryToJson(CompanySummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'company_name': instance.companyName,
    };

Offer _$OfferFromJson(Map<String, dynamic> json) => Offer(
  id: (json['id'] as num).toInt(),
  company: CompanySummary.fromJson(json['company'] as Map<String, dynamic>),
  title: json['title'] as String,
  description: json['description'] as String,
  skills: json['skills'] as String,
  location: json['location'] as String,
  durationWeeks: (json['duration_weeks'] as num).toInt(),
  startDate: json['start_date'] as String,
  positions: (json['positions'] as num).toInt(),
  status: json['status'] as String,
  isOpen: json['is_open'] as bool,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$OfferToJson(Offer instance) => <String, dynamic>{
  'id': instance.id,
  'company': instance.company,
  'title': instance.title,
  'description': instance.description,
  'skills': instance.skills,
  'location': instance.location,
  'duration_weeks': instance.durationWeeks,
  'start_date': instance.startDate,
  'positions': instance.positions,
  'status': instance.status,
  'is_open': instance.isOpen,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};

PaginatedOffers _$PaginatedOffersFromJson(Map<String, dynamic> json) =>
    PaginatedOffers(
      count: (json['count'] as num).toInt(),
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((e) => Offer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PaginatedOffersToJson(PaginatedOffers instance) =>
    <String, dynamic>{
      'count': instance.count,
      'next': instance.next,
      'previous': instance.previous,
      'results': instance.results,
    };
