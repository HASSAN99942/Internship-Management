// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthTokens _$AuthTokensFromJson(Map<String, dynamic> json) => AuthTokens(
  access: json['access'] as String,
  refresh: json['refresh'] as String,
);

AssignedTeacher _$AssignedTeacherFromJson(Map<String, dynamic> json) =>
    AssignedTeacher(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
    );

StudentProfile _$StudentProfileFromJson(Map<String, dynamic> json) =>
    StudentProfile(
      school: json['school'] as String?,
      program: json['program'] as String?,
      level: json['level'] as String?,
      phone: json['phone'] as String?,
      cvFile: json['cv_file'] as String?,
      assignedTeacher: json['assigned_teacher'] == null
          ? null
          : AssignedTeacher.fromJson(
              json['assigned_teacher'] as Map<String, dynamic>,
            ),
    );

CompanyProfile _$CompanyProfileFromJson(Map<String, dynamic> json) =>
    CompanyProfile(
      companyName: json['company_name'] as String?,
      sector: json['sector'] as String?,
      website: json['website'] as String?,
      address: json['address'] as String?,
      description: json['description'] as String?,
      contactPhone: json['contact_phone'] as String?,
    );

TeacherProfile _$TeacherProfileFromJson(Map<String, dynamic> json) =>
    TeacherProfile(
      department: json['department'] as String?,
      title: json['title'] as String?,
      phone: json['phone'] as String?,
    );
