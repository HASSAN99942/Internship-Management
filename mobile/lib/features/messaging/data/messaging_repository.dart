import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'models/message.dart';
import 'models/message_thread.dart';

class MessagingRepository {
  const MessagingRepository();

  Future<List<MessageThreadRow>> listThreads() async {
    final response = await apiClient.get('/threads/');
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => MessageThreadRow.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<ThreadDetail> getThread(int id) async {
    final response = await apiClient.get('/threads/$id/');
    return ThreadDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PaginatedMessages> listMessages(
    int threadId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await apiClient.get(
      '/threads/$threadId/messages/',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return PaginatedMessages.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Message> sendMessage(int threadId, String body) async {
    final response = await apiClient.post(
      '/threads/$threadId/messages/',
      data: {'body': body},
    );
    return Message.fromJson(response.data as Map<String, dynamic>);
  }

  Future<int> markThreadRead(int threadId) async {
    final response = await apiClient.post('/threads/$threadId/read/');
    final data = response.data as Map<String, dynamic>;
    return (data['marked_read'] as int?) ?? 0;
  }
}

final messagingRepositoryProvider =
    Provider<MessagingRepository>((_) => const MessagingRepository());
