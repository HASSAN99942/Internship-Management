import 'package:json_annotation/json_annotation.dart';

part 'message_thread.g.dart';

@JsonSerializable()
class ThreadParticipant {
  const ThreadParticipant({
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

  String get fullName => '$firstName $lastName'.trim();

  factory ThreadParticipant.fromJson(Map<String, dynamic> json) =>
      _$ThreadParticipantFromJson(json);
  Map<String, dynamic> toJson() => _$ThreadParticipantToJson(this);
}

@JsonSerializable()
class MessageThreadRow {
  const MessageThreadRow({
    required this.id,
    required this.internshipId,
    required this.offerTitle,
    required this.participants,
    required this.unreadCount,
    this.lastMessage,
    required this.lastActivity,
  });

  final int id;
  @JsonKey(name: 'internship_id')
  final int internshipId;
  @JsonKey(name: 'offer_title')
  final String offerTitle;
  final List<ThreadParticipant> participants;
  @JsonKey(name: 'unread_count')
  final int unreadCount;
  @JsonKey(name: 'last_message')
  final String? lastMessage;
  @JsonKey(name: 'last_activity')
  final String lastActivity;

  factory MessageThreadRow.fromJson(Map<String, dynamic> json) =>
      _$MessageThreadRowFromJson(json);
  Map<String, dynamic> toJson() => _$MessageThreadRowToJson(this);
}

@JsonSerializable()
class ThreadDetail {
  const ThreadDetail({
    required this.id,
    required this.internshipId,
    required this.offerTitle,
    required this.participants,
  });

  final int id;
  @JsonKey(name: 'internship_id')
  final int internshipId;
  @JsonKey(name: 'offer_title')
  final String offerTitle;
  final List<ThreadParticipant> participants;

  factory ThreadDetail.fromJson(Map<String, dynamic> json) =>
      _$ThreadDetailFromJson(json);
  Map<String, dynamic> toJson() => _$ThreadDetailToJson(this);
}
