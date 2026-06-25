import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

// ---------------------------------------------------------------------------
// Tokens
// ---------------------------------------------------------------------------

@JsonSerializable(createToJson: false)
class AuthTokens {
  const AuthTokens({required this.access, required this.refresh});

  final String access;
  final String refresh;

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);
}

// ---------------------------------------------------------------------------
// Profile sub-models (role-specific, json_serializable)
// ---------------------------------------------------------------------------

@JsonSerializable(createToJson: false)
class AssignedTeacher {
  const AssignedTeacher({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  final int id;
  final String email;
  @JsonKey(name: 'first_name')
  final String firstName;
  @JsonKey(name: 'last_name')
  final String lastName;

  String get displayName => '$firstName $lastName'.trim();

  factory AssignedTeacher.fromJson(Map<String, dynamic> json) =>
      _$AssignedTeacherFromJson(json);
}

@JsonSerializable(createToJson: false)
class StudentProfile {
  const StudentProfile({
    this.school,
    this.program,
    this.level,
    this.phone,
    this.cvFile,
    this.assignedTeacher,
  });

  final String? school;
  final String? program;
  final String? level;
  final String? phone;
  @JsonKey(name: 'cv_file')
  final String? cvFile;
  @JsonKey(name: 'assigned_teacher')
  final AssignedTeacher? assignedTeacher;

  factory StudentProfile.fromJson(Map<String, dynamic> json) =>
      _$StudentProfileFromJson(json);
}

@JsonSerializable(createToJson: false)
class CompanyProfile {
  const CompanyProfile({
    this.companyName,
    this.sector,
    this.website,
    this.address,
    this.description,
    this.contactPhone,
  });

  @JsonKey(name: 'company_name')
  final String? companyName;
  final String? sector;
  final String? website;
  final String? address;
  final String? description;
  @JsonKey(name: 'contact_phone')
  final String? contactPhone;

  factory CompanyProfile.fromJson(Map<String, dynamic> json) =>
      _$CompanyProfileFromJson(json);
}

@JsonSerializable(createToJson: false)
class TeacherProfile {
  const TeacherProfile({
    this.department,
    this.title,
    this.phone,
  });

  final String? department;
  final String? title;
  final String? phone;

  factory TeacherProfile.fromJson(Map<String, dynamic> json) =>
      _$TeacherProfileFromJson(json);
}

// ---------------------------------------------------------------------------
// User — written manually because `profile` is polymorphic on `role`.
// ---------------------------------------------------------------------------

class User {
  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isActive,
    this.studentProfile,
    this.companyProfile,
    this.teacherProfile,
  });

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final bool isActive;

  final StudentProfile? studentProfile;
  final CompanyProfile? companyProfile;
  final TeacherProfile? teacherProfile;

  String get displayName {
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty ? name : email;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as String;
    final rawProfile = json['profile'] as Map<String, dynamic>?;

    StudentProfile? studentProfile;
    CompanyProfile? companyProfile;
    TeacherProfile? teacherProfile;

    if (rawProfile != null) {
      switch (role) {
        case 'student':
          studentProfile = StudentProfile.fromJson(rawProfile);
        case 'company':
          companyProfile = CompanyProfile.fromJson(rawProfile);
        case 'teacher':
          teacherProfile = TeacherProfile.fromJson(rawProfile);
      }
    }

    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      role: role,
      isActive: json['is_active'] as bool? ?? true,
      studentProfile: studentProfile,
      companyProfile: companyProfile,
      teacherProfile: teacherProfile,
    );
  }
}
