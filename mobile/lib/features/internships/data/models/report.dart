import 'package:json_annotation/json_annotation.dart';
import 'internship.dart';

part 'report.g.dart';

@JsonSerializable()
class Report {
  final int id;
  final int internship;
  final PartySummary student;
  final String title;
  final String content;
  final String? file;
  final String period;
  // submitted | validated | changes_requested
  final String status;
  final String feedback;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const Report({
    required this.id,
    required this.internship,
    required this.student,
    required this.title,
    required this.content,
    this.file,
    required this.period,
    required this.status,
    required this.feedback,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) => _$ReportFromJson(json);
  Map<String, dynamic> toJson() => _$ReportToJson(this);
}
