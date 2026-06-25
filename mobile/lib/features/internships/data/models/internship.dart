import 'package:json_annotation/json_annotation.dart';
import 'task.dart';
import 'report.dart';

part 'internship.g.dart';

@JsonSerializable()
class PartySummary {
  final int id;
  final String email;
  @JsonKey(name: 'first_name')
  final String firstName;
  @JsonKey(name: 'last_name')
  final String lastName;

  const PartySummary({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory PartySummary.fromJson(Map<String, dynamic> json) =>
      _$PartySummaryFromJson(json);
  Map<String, dynamic> toJson() => _$PartySummaryToJson(this);
}

@JsonSerializable()
class Internship {
  final int id;
  final int application;
  @JsonKey(name: 'offer_title')
  final String offerTitle;
  final PartySummary student;
  final PartySummary company;
  final PartySummary? teacher;
  final String status; // pending_academic_validation|active|completed|cancelled
  @JsonKey(name: 'start_date')
  final String startDate;
  @JsonKey(name: 'end_date')
  final String endDate;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const Internship({
    required this.id,
    required this.application,
    required this.offerTitle,
    required this.student,
    required this.company,
    this.teacher,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Internship.fromJson(Map<String, dynamic> json) =>
      _$InternshipFromJson(json);
  Map<String, dynamic> toJson() => _$InternshipToJson(this);
}

@JsonSerializable()
class PaginatedInternships {
  final int count;
  final String? next;
  final String? previous;
  final List<Internship> results;

  const PaginatedInternships({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedInternships.fromJson(Map<String, dynamic> json) =>
      _$PaginatedInternshipsFromJson(json);
  Map<String, dynamic> toJson() => _$PaginatedInternshipsToJson(this);
}

// ---------------------------------------------------------------------------
// Dashboard aggregate (GET /internships/{id}/)
// ---------------------------------------------------------------------------

@JsonSerializable()
class InternshipProgress {
  @JsonKey(name: 'tasks_total')
  final int tasksTotal;
  @JsonKey(name: 'tasks_validated')
  final int tasksValidated;
  @JsonKey(name: 'tasks_validated_pct')
  final int tasksValidatedPct;
  @JsonKey(name: 'reports_total')
  final int reportsTotal;
  @JsonKey(name: 'reports_validated')
  final int reportsValidated;
  @JsonKey(name: 'reports_validated_pct')
  final int reportsValidatedPct;

  const InternshipProgress({
    required this.tasksTotal,
    required this.tasksValidated,
    required this.tasksValidatedPct,
    required this.reportsTotal,
    required this.reportsValidated,
    required this.reportsValidatedPct,
  });

  factory InternshipProgress.fromJson(Map<String, dynamic> json) =>
      _$InternshipProgressFromJson(json);
  Map<String, dynamic> toJson() => _$InternshipProgressToJson(this);
}

/// Aggregate returned by GET /internships/{id}/.
class InternshipDashboard {
  final Internship internship;
  final List<Task> tasks;
  final List<Report> reports;
  final InternshipProgress progress;

  const InternshipDashboard({
    required this.internship,
    required this.tasks,
    required this.reports,
    required this.progress,
  });

  factory InternshipDashboard.fromJson(Map<String, dynamic> json) =>
      InternshipDashboard(
        internship:
            Internship.fromJson(json['internship'] as Map<String, dynamic>),
        tasks: (json['tasks'] as List<dynamic>? ?? [])
            .map((e) => Task.fromJson(e as Map<String, dynamic>))
            .toList(),
        reports: (json['reports'] as List<dynamic>? ?? [])
            .map((e) => Report.fromJson(e as Map<String, dynamic>))
            .toList(),
        progress: InternshipProgress.fromJson(
            json['progress'] as Map<String, dynamic>),
      );
}
