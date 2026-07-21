import 'package:bigstyle_app/models/chat_message_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatMessageModel Supabase mapping', () {
    test('toMap writes role, not the nonexistent is_from_ai column', () {
      final aiMessage = ChatMessageModel(
        id: 'msg-1',
        userId: 'user-1',
        content: 'hello',
        isFromAi: true,
        createdAt: DateTime(2026),
      );
      final map = aiMessage.toMap();

      expect(map['role'], 'assistant');
      expect(map.containsKey('is_from_ai'), isFalse);
    });

    test('toMap maps a user message to role "user"', () {
      final userMessage = ChatMessageModel(
        id: 'msg-2',
        userId: 'user-1',
        content: 'hi',
        isFromAi: false,
        createdAt: DateTime(2026),
      );

      expect(userMessage.toMap()['role'], 'user');
    });

    test('fromMap reads role "assistant" into isFromAi=true', () {
      final message = ChatMessageModel.fromMap({
        'id': 'msg-1',
        'user_id': 'user-1',
        'content': 'hello',
        'role': 'assistant',
        'created_at': '2026-01-01T00:00:00.000Z',
      });

      expect(message.isFromAi, isTrue);
    });

    test('fromMap reads role "user" into isFromAi=false', () {
      final message = ChatMessageModel.fromMap({
        'id': 'msg-2',
        'user_id': 'user-1',
        'content': 'hi',
        'role': 'user',
        'created_at': '2026-01-01T00:00:00.000Z',
      });

      expect(message.isFromAi, isFalse);
    });
  });
}
