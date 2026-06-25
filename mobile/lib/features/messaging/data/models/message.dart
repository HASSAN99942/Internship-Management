import 'package:json_annotation/json_annotation.dart';

part 'message.g.dart';

@JsonSerializable()
class MessageSender {
  const MessageSender({
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

  factory MessageSender.fromJson(Map<String, dynamic> json) =>
      _$MessageSenderFromJson(json);
  Map<String, dynamic> toJson() => _$MessageSenderToJson(this);
}

@JsonSerializable()
class Message {
  const Message({
    required this.id,
    required this.thread,
    required this.sender,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final int thread;
  final MessageSender sender;
  final String body;
  @JsonKey(name: 'is_read')
  final bool isRead;
  @JsonKey(name: 'created_at')
  final String createdAt;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);
}

@JsonSerializable(createToJson: false)
class PaginatedMessages {
  const PaginatedMessages({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<Message> results;

  factory PaginatedMessages.fromJson(Map<String, dynamic> json) =>
      _$PaginatedMessagesFromJson(json);
}
