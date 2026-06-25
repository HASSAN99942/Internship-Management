// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Report _$ReportFromJson(Map<String, dynamic> json) => Report(
  id: (json['id'] as num).toInt(),
  internship: (json['internship'] as num).toInt(),
  student: PartySummary.fromJson(json['student'] as Map<String, dynamic>),
  title: json['title'] as String,
  content: json['content'] as String,
  file: json['file'] as String?,
  period: json['period'] as String,
  status: json['status'] as String,
  feedback: json['feedback'] as String,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$ReportToJson(Report instance) => <String, dynamic>{
  'id': instance.id,
  'internship': instance.internship,
  'student': instance.student,
  'title': instance.title,
  'content': instance.content,
  'file': instance.file,
  'period': instance.period,
  'status': instance.status,
  'feedback': instance.feedback,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};
