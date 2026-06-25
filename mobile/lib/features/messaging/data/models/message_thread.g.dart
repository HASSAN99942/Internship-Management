// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_thread.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ThreadParticipant _$ThreadParticipantFromJson(Map<String, dynamic> json) =>
    ThreadParticipant(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
    );

Map<String, dynamic> _$ThreadParticipantToJson(ThreadParticipant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
    };

MessageThreadRow _$MessageThreadRowFromJson(Map<String, dynamic> json) =>
    MessageThreadRow(
      id: (json['id'] as num).toInt(),
      internshipId: (json['internship_id'] as num).toInt(),
      offerTitle: json['offer_title'] as String,
      participants: (json['participants'] as List<dynamic>)
          .map((e) => ThreadParticipant.fromJson(e as Map<String, dynamic>))
          .toList(),
      unreadCount: (json['unread_count'] as num).toInt(),
      lastMessage: json['last_message'] as String?,
      lastActivity: json['last_activity'] as String,
    );

Map<String, dynamic> _$MessageThreadRowToJson(MessageThreadRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'internship_id': instance.internshipId,
      'offer_title': instance.offerTitle,
      'participants': instance.participants,
      'unread_count': instance.unreadCount,
      'last_message': instance.lastMessage,
      'last_activity': instance.lastActivity,
    };

ThreadDetail _$ThreadDetailFromJson(Map<String, dynamic> json) => ThreadDetail(
  id: (json['id'] as num).toInt(),
  internshipId: (json['internship_id'] as num).toInt(),
  offerTitle: json['offer_title'] as String,
  participants: (json['participants'] as List<dynamic>)
      .map((e) => ThreadParticipant.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ThreadDetailToJson(ThreadDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'internship_id': instance.internshipId,
      'offer_title': instance.offerTitle,
      'participants': instance.participants,
    };
