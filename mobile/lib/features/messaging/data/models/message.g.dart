// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageSender _$MessageSenderFromJson(Map<String, dynamic> json) =>
    MessageSender(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
    );

Map<String, dynamic> _$MessageSenderToJson(MessageSender instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
    };

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
  id: (json['id'] as num).toInt(),
  thread: (json['thread'] as num).toInt(),
  sender: MessageSender.fromJson(json['sender'] as Map<String, dynamic>),
  body: json['body'] as String,
  isRead: json['is_read'] as bool,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
  'id': instance.id,
  'thread': instance.thread,
  'sender': instance.sender,
  'body': instance.body,
  'is_read': instance.isRead,
  'created_at': instance.createdAt,
};

PaginatedMessages _$PaginatedMessagesFromJson(Map<String, dynamic> json) =>
    PaginatedMessages(
      count: (json['count'] as num).toInt(),
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
