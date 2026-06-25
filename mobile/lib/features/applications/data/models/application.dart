import 'package:json_annotation/json_annotation.dart';

part 'application.g.dart';

@JsonSerializable()
class OfferSummary {
  final int id;
  final String title;

  const OfferSummary({required this.id, required this.title});

  factory OfferSummary.fromJson(Map<String, dynamic> json) =>
      _$OfferSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$OfferSummaryToJson(this);
}

@JsonSerializable()
class ApplicantSummary {
  final int id;
  final String email;
  @JsonKey(name: 'first_name')
  final String firstName;
  @JsonKey(name: 'last_name')
  final String lastName;

  const ApplicantSummary({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ApplicantSummary.fromJson(Map<String, dynamic> json) =>
      _$ApplicantSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$ApplicantSummaryToJson(this);
}

@JsonSerializable()
class Application {
  final int id;
  final OfferSummary offer;
  final ApplicantSummary student;
  @JsonKey(name: 'cover_message')
  final String coverMessage;
  @JsonKey(name: 'cv_file')
  final String? cvFile;
  final String status; // pending | accepted | rejected | withdrawn
  @JsonKey(name: 'decided_at')
  final String? decidedAt;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const Application({
    required this.id,
    required this.offer,
    required this.student,
    required this.coverMessage,
    this.cvFile,
    required this.status,
    this.decidedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Application.fromJson(Map<String, dynamic> json) =>
      _$ApplicationFromJson(json);
  Map<String, dynamic> toJson() => _$ApplicationToJson(this);
}

@JsonSerializable()
class PaginatedApplications {
  final int count;
  final String? next;
  final String? previous;
  final List<Application> results;

  const PaginatedApplications({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedApplications.fromJson(Map<String, dynamic> json) =>
      _$PaginatedApplicationsFromJson(json);
  Map<String, dynamic> toJson() => _$PaginatedApplicationsToJson(this);
}
