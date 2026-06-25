import 'package:json_annotation/json_annotation.dart';
import 'internship.dart';

part 'task.g.dart';

@JsonSerializable()
class Task {
  final int id;
  final int internship;
  @JsonKey(name: 'created_by')
  final PartySummary? createdBy;
  final String title;
  final String description;
  @JsonKey(name: 'due_date')
  final String? dueDate;
  // open | submitted | validated | changes_requested
  final String status;
  @JsonKey(name: 'submission_note')
  final String submissionNote;
  @JsonKey(name: 'submission_file')
  final String? submissionFile;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const Task({
    required this.id,
    required this.internship,
    this.createdBy,
    required this.title,
    required this.description,
    this.dueDate,
    required this.status,
    required this.submissionNote,
    this.submissionFile,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);
}

class TaskInput {
  const TaskInput({
    required this.title,
    this.description = '',
    this.dueDate,
  });

  final String title;
  final String description;
  final String? dueDate;

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        if (dueDate != null) 'due_date': dueDate,
      };
}
