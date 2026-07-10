import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/support_chat_service.dart';
import 'support_chat_event.dart';
import 'support_chat_state.dart';

/// Screen-scoped thread bloc. Provided per route (never app-scoped) so
/// switching conversations can't race a previous subscription's late events
/// into the new thread, and the subscription is deterministically closed.
class SupportChatBloc extends Bloc<SupportChatEvent, SupportChatState> {
  final SupportChatService _service;
  StreamSubscription? _subscription;

  SupportChatBloc(this._service) : super(const SupportChatState()) {
    on<SupportChatOpenMine>(_onOpenMine);
    on<SupportChatSubscribe>(_onSubscribe);
    on<SupportChatMessagesUpdated>(_onMessagesUpdated);
    on<SupportChatSend>(_onSend);
  }

  Future<void> _onOpenMine(
    SupportChatOpenMine event,
    Emitter<SupportChatState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final conversation = await _service.getOrCreateConversation();
      add(SupportChatSubscribe(conversation.id));
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Không mở được cuộc trò chuyện',
        ),
      );
    }
  }

  Future<void> _onSubscribe(
    SupportChatSubscribe event,
    Emitter<SupportChatState> emit,
  ) async {
    await _subscription?.cancel();
    emit(
      state.copyWith(
        conversationId: event.conversationId,
        messages: const [],
        isLoading: true,
        clearError: true,
      ),
    );
    // Mark read on open (fire-and-forget); counterpart messages clear unread.
    unawaited(_service.markRead(event.conversationId).catchError((_) {}));

    final conversationId = event.conversationId;
    _subscription = _service.messagesStream(conversationId).listen(
      (messages) =>
          add(SupportChatMessagesUpdated(conversationId, messages)),
      onError: (_) => add(SupportChatMessagesUpdated(conversationId, null)),
    );
  }

  void _onMessagesUpdated(
    SupportChatMessagesUpdated event,
    Emitter<SupportChatState> emit,
  ) {
    // Drop stale emissions from a previous conversation's subscription.
    if (event.conversationId != state.conversationId) return;
    if (event.messages == null) {
      emit(state.copyWith(isLoading: false, error: 'Tải tin nhắn thất bại'));
      return;
    }
    emit(
      state.copyWith(
        isLoading: false,
        messages: event.messages,
        clearError: true,
      ),
    );
  }

  Future<void> _onSend(
    SupportChatSend event,
    Emitter<SupportChatState> emit,
  ) async {
    final conversationId = state.conversationId;
    if (conversationId == null) return;
    try {
      // The sent message arrives back through the live stream.
      await _service.sendMessage(
        conversationId: conversationId,
        senderId: event.senderId,
        content: event.content,
      );
    } catch (_) {
      emit(state.copyWith(error: 'Gửi tin nhắn thất bại'));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
