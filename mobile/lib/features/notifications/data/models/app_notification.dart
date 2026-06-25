import 'package:json_annotation/json_annotation.dart';

part 'app_notification.g.dart';

@JsonSerializable()
class NotificationPayload {
  const NotificationPayload({
    required this.message,
    required this.route,
  });

  final String message;
  final String route;

  factory NotificationPayload.fromJson(Map<String, dynamic> json) =>
      _$NotificationPayloadFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationPayloadToJson(this);
}

@JsonSerializable()
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.payload,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final String type;
  final NotificationPayload payload;
  @JsonKey(name: 'is_read')
  final bool isRead;
  @JsonKey(name: 'created_at')
  final String createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
  Map<String, dynamic> toJson() => _$AppNotificationToJson(this);
}

@JsonSerializable(createToJson: false)
class PaginatedNotifications {
  const PaginatedNotifications({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<AppNotification> results;

  factory PaginatedNotifications.fromJson(Map<String, dynamic> json) =>
      _$PaginatedNotificationsFromJson(json);
}
