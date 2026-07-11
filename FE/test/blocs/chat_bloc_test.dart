import 'package:bigstyle_app/blocs/chat/chat_bloc.dart';
import 'package:bigstyle_app/blocs/chat/chat_event.dart';
import 'package:bigstyle_app/blocs/chat/chat_state.dart';
import 'package:bigstyle_app/models/chat_message_model.dart';
import 'package:bigstyle_app/services/chat_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeChatService extends ChatService {
  _FakeChatService()
      : super(
          client: SupabaseClient(
            'https://example.supabase.co',
            'dummy-anon-key',
          ),
        );

  int saveMessageCalls = 0;
  int getAiResponseCalls = 0;
  final savedContents = <String>[];
  String? lastAiRequestMessage;

  @override
  Future<void> saveMessage(ChatMessageModel message) async {
    saveMessageCalls++;
    savedContents.add(message.content);
  }

  @override
  Future<String> getAiResponse(
      String message, List<ChatMessageModel> history) async {
    getAiResponseCalls++;
    lastAiRequestMessage = message;
    return 'mock response';
  }
}

void main() {
  group('ChatBloc', () {
    test('rejects a message over 1000 characters before saving or calling the AI',
        () async {
      final fakeService = _FakeChatService();
      final bloc = ChatBloc(fakeService);

      final tooLong = 'a' * 1001;
      bloc.add(ChatSendMessage('user-1', tooLong));

      await expectLater(
        bloc.stream,
        emits(
          isA<ChatState>()
              .having((s) => s.isSending, 'isSending', false)
              .having((s) => s.error, 'error', isNotNull),
        ),
      );

      expect(fakeService.saveMessageCalls, 0);
      expect(fakeService.getAiResponseCalls, 0);

      await bloc.close();
    });

    test('accepts a message at exactly 1000 characters', () async {
      final fakeService = _FakeChatService();
      final bloc = ChatBloc(fakeService);

      final atLimit = 'a' * 1000;
      bloc.add(ChatSendMessage('user-1', atLimit));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ChatState>().having((s) => s.isSending, 'isSending', true),
          isA<ChatState>().having((s) => s.isSending, 'isSending', false),
        ]),
      );

      expect(fakeService.getAiResponseCalls, 1);

      await bloc.close();
    });

    test(
        'measures the length limit against trimmed content, and persists/sends '
        'the trimmed content (not the padded original)', () async {
      final fakeService = _FakeChatService();
      final bloc = ChatBloc(fakeService);

      // 2000 leading spaces + a short word: trims to 3 chars (well under the
      // limit) but the raw string is 2003 chars — the guard must measure the
      // trimmed length, and whatever passes the guard must be what actually
      // gets persisted and sent to the AI, not the untrimmed original.
      final paddedButShort = '${' ' * 2000}abc';
      bloc.add(ChatSendMessage('user-1', paddedButShort));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ChatState>().having((s) => s.isSending, 'isSending', true),
          isA<ChatState>().having((s) => s.isSending, 'isSending', false),
        ]),
      );

      expect(fakeService.getAiResponseCalls, 1);
      expect(fakeService.lastAiRequestMessage, 'abc');
      // First saveMessage call is the user's own (trimmed) message; the
      // second is the AI reply — both must reflect the trimmed content, not
      // the 2000-space-padded original.
      expect(fakeService.savedContents.first, 'abc');

      await bloc.close();
    });
  });
}
