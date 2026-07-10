import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/support_chat_service.dart';
import 'support_inbox_event.dart';
import 'support_inbox_state.dart';

/// App-scoped staff inbox bloc (single logical stream). Ordering + unread come
/// denormalized from the conversation rows, so there are no per-row queries.
class SupportInboxBloc extends Bloc<SupportInboxEvent, SupportInboxState> {
  final SupportChatService _service;
  StreamSubscription? _subscription;

  SupportInboxBloc(this._service) : super(const SupportInboxState()) {
    on<SupportInboxSubscribe>(_onSubscribe);
    on<SupportInboxUpdated>(_onUpdated);
  }

  Future<void> _onSubscribe(
    SupportInboxSubscribe event,
    Emitter<SupportInboxState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = _service.conversationsStream().listen(
      (conversations) => add(SupportInboxUpdated(conversations)),
      onError: (_) => add(const SupportInboxUpdated(null)),
    );
  }

  void _onUpdated(
    SupportInboxUpdated event,
    Emitter<SupportInboxState> emit,
  ) {
    if (event.conversations == null) {
      emit(state.copyWith(isLoading: false, error: 'Tải hộp thư thất bại'));
      return;
    }
    emit(
      state.copyWith(
        isLoading: false,
        conversations: event.conversations,
        clearError: true,
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
