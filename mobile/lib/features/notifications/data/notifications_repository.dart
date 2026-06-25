import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'models/app_notification.dart';

class NotificationsRepository {
  const NotificationsRepository();

  Future<PaginatedNotifications> listNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await apiClient.get(
      '/notifications/',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return PaginatedNotifications.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<int> fetchUnreadCount() async {
    final response = await apiClient.get('/notifications/unread-count/');
    final data = response.data as Map<String, dynamic>;
    return (data['unread'] as num).toInt();
  }

  Future<AppNotification> markRead(int id) async {
    final response = await apiClient.post('/notifications/$id/read/');
    return AppNotification.fromJson(response.data as Map<String, dynamic>);
  }

  Future<int> markAllRead() async {
    final response = await apiClient.post('/notifications/read-all/');
    final data = response.data as Map<String, dynamic>;
    return (data['marked_read'] as num).toInt();
  }
}

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((_) => const NotificationsRepository());
