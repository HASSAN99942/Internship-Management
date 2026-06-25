// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task _$TaskFromJson(Map<String, dynamic> json) => Task(
  id: (json['id'] as num).toInt(),
  internship: (json['internship'] as num).toInt(),
  createdBy: json['created_by'] == null
      ? null
      : PartySummary.fromJson(json['created_by'] as Map<String, dynamic>),
  title: json['title'] as String,
  description: json['description'] as String,
  dueDate: json['due_date'] as String?,
  status: json['status'] as String,
  submissionNote: json['submission_note'] as String,
  submissionFile: json['submission_file'] as String?,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
  'id': instance.id,
  'internship': instance.internship,
  'created_by': instance.createdBy,
  'title': instance.title,
  'description': instance.description,
  'due_date': instance.dueDate,
  'status': instance.status,
  'submission_note': instance.submissionNote,
  'submission_file': instance.submissionFile,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};
