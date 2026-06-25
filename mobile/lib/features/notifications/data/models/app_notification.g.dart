// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationPayload _$NotificationPayloadFromJson(Map<String, dynamic> json) =>
    NotificationPayload(
      message: json['message'] as String,
      route: json['route'] as String,
    );

Map<String, dynamic> _$NotificationPayloadToJson(
  NotificationPayload instance,
) => <String, dynamic>{'message': instance.message, 'route': instance.route};

AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    AppNotification(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String,
      payload: NotificationPayload.fromJson(
        json['payload'] as Map<String, dynamic>,
      ),
      isRead: json['is_read'] as bool,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$AppNotificationToJson(AppNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'payload': instance.payload,
      'is_read': instance.isRead,
      'created_at': instance.createdAt,
    };

PaginatedNotifications _$PaginatedNotificationsFromJson(
  Map<String, dynamic> json,
) => PaginatedNotifications(
  count: (json['count'] as num).toInt(),
  next: json['next'] as String?,
  previous: json['previous'] as String?,
  results: (json['results'] as List<dynamic>)
      .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
      .toList(),
);
