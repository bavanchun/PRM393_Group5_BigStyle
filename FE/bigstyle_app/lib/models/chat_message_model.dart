import 'package:equatable/equatable.dart';

class ChatMessageModel extends Equatable {
  final String id;
  final String userId;
  final String content;
  final bool isFromAi;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.userId,
    required this.content,
    this.isFromAi = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'content': content,
        'is_from_ai': isFromAi,
        'created_at': createdAt.toIso8601String(),
      };

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) =>
      ChatMessageModel(
        id: map['id'] ?? '',
        userId: map['user_id'] ?? '',
        content: map['content'] ?? '',
        isFromAi: map['is_from_ai'] ?? false,
        createdAt:
            DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [id, userId, content, isFromAi, createdAt];
}
