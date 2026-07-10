import 'dart:async';

import 'package:bigstyle_app/blocs/support_inbox/support_inbox_bloc.dart';
import 'package:bigstyle_app/blocs/support_inbox/support_inbox_event.dart';
import 'package:bigstyle_app/models/support_conversation_model.dart';
import 'package:bigstyle_app/services/support_chat_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeSupportChatService extends SupportChatService {
  FakeSupportChatService()
    : super(client: SupabaseClient('http://localhost', 'anon-key'));

  final controller =
      StreamController<List<SupportConversationModel>>.broadcast();

  @override
  Stream<List<SupportConversationModel>> conversationsStream() =>
      controller.stream;
}

SupportConversationModel _conv(String id, DateTime at, int unread) =>
    SupportConversationModel(
      id: id,
      customerId: 'c-$id',
      status: 'open',
      lastMessageAt: at,
      unreadForStaff: unread,
    );

void main() {
  test('inbox surfaces the ordered list and sums denormalized unread',
      () async {
    final service = FakeSupportChatService();
    final bloc = SupportInboxBloc(service);

    bloc.add(const SupportInboxSubscribe());
    await Future<void>.delayed(Duration.zero);

    // Server orders by last_message_at desc; bloc passes the snapshot through.
    service.controller.add([
      _conv('a', DateTime(2026, 7, 11, 10), 2),
      _conv('b', DateTime(2026, 7, 11, 9), 3),
    ]);

    final state =
        await bloc.stream.firstWhere((s) => s.conversations.isNotEmpty);
    expect(state.conversations.map((c) => c.id), ['a', 'b']);
    expect(state.totalUnread, 5);
    expect(state.isLoading, isFalse);
    await bloc.close();
  });
}
