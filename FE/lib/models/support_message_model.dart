import 'package:equatable/equatable.dart';

/// A single message in a human support conversation (support_messages row).
class SupportMessageModel extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final DateTime? readAt;

  const SupportMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.readAt,
  });

  factory SupportMessageModel.fromMap(Map<String, dynamic> map) {
    return SupportMessageModel(
      id: map['id'] as String? ?? '',
      conversationId: map['conversation_id'] as String? ?? '',
      senderId: map['sender_id'] as String? ?? '',
      content: map['content'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      readAt: map['read_at'] != null
          ? DateTime.tryParse(map['read_at'] as String)?.toLocal()
          : null,
    );
  }

  @override
  List<Object?> get props =>
      [id, conversationId, senderId, content, createdAt, readAt];
}
