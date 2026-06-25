import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'models/application.dart';

class ApplicationsRepository {
  const ApplicationsRepository();

  Future<List<Application>> listApplications() async {
    final response = await apiClient.get('/applications/');
    final data = response.data as Map<String, dynamic>;
    return PaginatedApplications.fromJson(data).results;
  }

  Future<Application> getApplication(int id) async {
    final response = await apiClient.get('/applications/$id/');
    return Application.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Application> apply(
    int offerId, {
    required String coverMessage,
    PlatformFile? cvFile,
  }) async {
    final Map<String, dynamic> fields = {'cover_message': coverMessage};

    if (cvFile != null) {
      final bytes = cvFile.bytes;
      if (bytes == null) throw Exception('Could not read file bytes.');
      fields['cv_file'] = MultipartFile.fromBytes(
        bytes,
        filename: cvFile.name,
      );
    }

    final response = await apiClient.post(
      '/offers/$offerId/apply/',
      data: FormData.fromMap(fields),
      options: Options(contentType: 'multipart/form-data'),
    );
    return Application.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Application> accept(int id) async {
    final response = await apiClient.post('/applications/$id/accept/');
    return Application.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Application> reject(int id) async {
    final response = await apiClient.post('/applications/$id/reject/');
    return Application.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Application> withdraw(int id) async {
    final response = await apiClient.post('/applications/$id/withdraw/');
    return Application.fromJson(response.data as Map<String, dynamic>);
  }
}

final applicationsRepositoryProvider =
    Provider<ApplicationsRepository>((_) => const ApplicationsRepository());
