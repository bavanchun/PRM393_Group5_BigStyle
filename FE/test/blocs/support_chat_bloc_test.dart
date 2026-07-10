import 'dart:async';

import 'package:bigstyle_app/blocs/support_chat/support_chat_bloc.dart';
import 'package:bigstyle_app/blocs/support_chat/support_chat_event.dart';
import 'package:bigstyle_app/models/support_conversation_model.dart';
import 'package:bigstyle_app/models/support_message_model.dart';
import 'package:bigstyle_app/services/support_chat_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeSupportChatService extends SupportChatService {
  FakeSupportChatService()
    : super(client: SupabaseClient('http://localhost', 'anon-key'));

  final Map<String, StreamController<List<SupportMessageModel>>> controllers =
      {};
  int cancelCount = 0;
  int markReadCount = 0;
  final List<String> sent = [];

  StreamController<List<SupportMessageModel>> controllerFor(String id) {
    return controllers.putIfAbsent(
      id,
      () => StreamController<List<SupportMessageModel>>(
        onCancel: () => cancelCount++,
      ),
    );
  }

  @override
  Stream<List<SupportMessageModel>> messagesStream(String conversationId) =>
      controllerFor(conversationId).stream;

  String myConversationId = 'A';

  @override
  Future<SupportConversationModel> getOrCreateConversation() async =>
      SupportConversationModel(
        id: myConversationId,
        customerId: 'u1',
        status: 'open',
        lastMessageAt: DateTime(2026, 7, 11),
      );

  @override
  Future<void> markRead(String conversationId) async => markReadCount++;

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async =>
      sent.add(content);
}

SupportMessageModel _msg(String id, String conv, String content) =>
    SupportMessageModel(
      id: id,
      conversationId: conv,
      senderId: 'u1',
      content: content,
      createdAt: DateTime(2026, 7, 11),
    );

Future<void> _tick() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeSupportChatService service;
  late SupportChatBloc bloc;

  setUp(() {
    service = FakeSupportChatService();
    bloc = SupportChatBloc(service);
  });

  test('subscribe streams messages and marks the conversation read', () async {
    bloc.add(const SupportChatSubscribe('A'));
    await bloc.stream.firstWhere((s) => s.conversationId == 'A');
    service.controllerFor('A').add([_msg('m1', 'A', 'hi')]);

    final state = await bloc.stream.firstWhere((s) => s.messages.isNotEmpty);
    expect(state.messages.single.content, 'hi');
    expect(service.markReadCount, 1);
    await bloc.close();
  });

  test('openMine resolves the caller conversation then subscribes', () async {
    bloc.add(const SupportChatOpenMine());
    await bloc.stream.firstWhere((s) => s.conversationId == 'A');
    service.controllerFor('A').add([_msg('m1', 'A', 'hi')]);

    final state = await bloc.stream.firstWhere((s) => s.messages.isNotEmpty);
    expect(state.messages.single.content, 'hi');
    expect(service.markReadCount, 1);
    await bloc.close();
  });

  test('send forwards content to the service', () async {
    bloc.add(const SupportChatSubscribe('A'));
    await bloc.stream.firstWhere((s) => s.conversationId == 'A');

    bloc.add(const SupportChatSend(senderId: 'u1', content: 'hello'));
    await _tick();
    expect(service.sent, ['hello']);
    await bloc.close();
  });

  test('close cancels the active subscription', () async {
    bloc.add(const SupportChatSubscribe('A'));
    await bloc.stream.firstWhere((s) => s.conversationId == 'A');
    await bloc.close();
    expect(service.cancelCount, 1);
  });

  test('switching conversations drops late events from the previous one',
      () async {
    bloc.add(const SupportChatSubscribe('A'));
    await bloc.stream.firstWhere((s) => s.conversationId == 'A');
    service.controllerFor('A').add([_msg('a1', 'A', 'from A')]);
    await bloc.stream.firstWhere((s) => s.messages.isNotEmpty);

    bloc.add(const SupportChatSubscribe('B'));
    await bloc.stream.firstWhere(
      (s) => s.conversationId == 'B' && s.messages.isEmpty,
    );
    // A subscription is cancelled on switch.
    expect(service.cancelCount, 1);

    // A late A emission must not leak into B's view.
    service.controllerFor('A').add([_msg('a2', 'A', 'late A')]);
    service.controllerFor('B').add([_msg('b1', 'B', 'from B')]);

    final state = await bloc.stream.firstWhere((s) => s.messages.isNotEmpty);
    expect(state.conversationId, 'B');
    expect(state.messages.map((m) => m.content), ['from B']);
    await bloc.close();
  });
}
