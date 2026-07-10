import 'package:bigstyle_app/models/support_conversation_model.dart';
import 'package:bigstyle_app/models/support_message_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SupportMessageModel.fromMap parses fields', () {
    final m = SupportMessageModel.fromMap({
      'id': 'm1',
      'conversation_id': 'c1',
      'sender_id': 'u1',
      'content': 'xin chào',
      'created_at': '2026-07-11T03:00:00Z',
      'read_at': null,
    });
    expect(m.id, 'm1');
    expect(m.conversationId, 'c1');
    expect(m.content, 'xin chào');
    expect(m.readAt, isNull);
  });

  test('SupportConversationModel.fromMap parses denormalized counters', () {
    final c = SupportConversationModel.fromMap({
      'id': 'c1',
      'customer_id': 'u1',
      'status': 'open',
      'last_message_at': '2026-07-11T03:00:00Z',
      'last_message_preview': 'preview',
      'unread_for_staff': 4,
      'unread_for_customer': 1,
    });
    expect(c.id, 'c1');
    expect(c.lastMessagePreview, 'preview');
    expect(c.unreadForStaff, 4);
    expect(c.unreadForCustomer, 1);
  });
}
