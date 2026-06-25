import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'models/internship.dart';
import 'models/task.dart';
import 'models/report.dart';

class InternshipsRepository {
  const InternshipsRepository();

  // ---------------------------------------------------------------------------
  // Internships
  // ---------------------------------------------------------------------------

  Future<List<Internship>> listInternships() async {
    final response = await apiClient.get('/internships/');
    final data = response.data as Map<String, dynamic>;
    return PaginatedInternships.fromJson(data).results;
  }

  Future<InternshipDashboard> getInternship(int id) async {
    final response = await apiClient.get('/internships/$id/');
    return InternshipDashboard.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<Internship> validate(int id) async {
    final response = await apiClient.post('/internships/$id/validate/');
    return Internship.fromJson(response.data as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // Tasks
  // ---------------------------------------------------------------------------

  Future<List<Task>> listTasks(int internshipId) async {
    final response = await apiClient.get('/internships/$internshipId/tasks/');
    final raw = response.data;
    if (raw is List) {
      return raw
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final data = raw as Map<String, dynamic>;
    return (data['results'] as List<dynamic>)
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Task> createTask(int internshipId, TaskInput input) async {
    final response = await apiClient.post(
      '/internships/$internshipId/tasks/',
      data: input.toJson(),
    );
    return Task.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Task> submitTask(
    int taskId, {
    required String note,
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    final form = FormData.fromMap({
      'submission_note': note,
      if (filePath != null)
        'submission_file': await MultipartFile.fromFile(filePath,
            filename: fileName ?? filePath.split('/').last),
      if (fileBytes != null && fileName != null)
        'submission_file':
            MultipartFile.fromBytes(fileBytes, filename: fileName),
    });
    final response = await apiClient.post(
      '/tasks/$taskId/submit/',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return Task.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Task> validateTask(int taskId) async {
    final response = await apiClient.post('/tasks/$taskId/validate/');
    return Task.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Task> requestTaskChanges(int taskId) async {
    final response =
        await apiClient.post('/tasks/$taskId/request-changes/');
    return Task.fromJson(response.data as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // Reports
  // ---------------------------------------------------------------------------

  Future<List<Report>> listReports(int internshipId) async {
    final response =
        await apiClient.get('/internships/$internshipId/reports/');
    final raw = response.data;
    if (raw is List) {
      return raw
          .map((e) => Report.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final data = raw as Map<String, dynamic>;
    return (data['results'] as List<dynamic>)
        .map((e) => Report.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Report> submitReport(
    int internshipId, {
    required String title,
    required String period,
    required String content,
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    final form = FormData.fromMap({
      'title': title,
      'period': period,
      'content': content,
      if (filePath != null)
        'file': await MultipartFile.fromFile(filePath,
            filename: fileName ?? filePath.split('/').last),
      if (fileBytes != null && fileName != null)
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });
    final response = await apiClient.post(
      '/internships/$internshipId/reports/',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return Report.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Report> validateReport(int reportId) async {
    final response = await apiClient.post('/reports/$reportId/validate/');
    return Report.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Report> requestReportChanges(
      int reportId, String feedback) async {
    final response = await apiClient.post(
      '/reports/$reportId/request-changes/',
      data: {'feedback': feedback},
    );
    return Report.fromJson(response.data as Map<String, dynamic>);
  }
}

final internshipsRepositoryProvider =
    Provider<InternshipsRepository>((_) => const InternshipsRepository());
