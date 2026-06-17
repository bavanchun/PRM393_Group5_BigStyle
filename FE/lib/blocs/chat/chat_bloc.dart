import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import '../../models/chat_message_model.dart';
import '../../services/chat_service.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatService _chatService;

  ChatBloc(this._chatService) : super(const ChatState()) {
    on<ChatLoadHistory>(_onLoadHistory);
    on<ChatSendMessage>(_onSendMessage);
  }

  Future<void> _onLoadHistory(
      ChatLoadHistory event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isLoading: true));
    await Future.delayed(const Duration(milliseconds: 300));
    emit(state.copyWith(
      isLoading: false,
      messages: [
        ChatMessageModel(
          id: const Uuid().v4(),
          userId: event.userId,
          content:
              'Xin chào! Tôi là trợ lý của BigStyle. Tôi có thể giúp gì cho bạn về thời trang bigsize?',
          isFromAi: true,
          createdAt: DateTime.now(),
        ),
      ],
    ));
  }

  Future<void> _onSendMessage(
      ChatSendMessage event, Emitter<ChatState> emit) async {
    final userMessage = ChatMessageModel(
      id: const Uuid().v4(),
      userId: event.userId,
      content: event.content,
      isFromAi: false,
      createdAt: DateTime.now(),
    );

    emit(state.copyWith(
      isSending: true,
      messages: [...state.messages, userMessage],
    ));

    try {
      final aiResponse = await _chatService.getAiResponse(
        event.content,
        state.messages,
      );

      final aiMessage = ChatMessageModel(
        id: const Uuid().v4(),
        userId: event.userId,
        content: aiResponse,
        isFromAi: true,
        createdAt: DateTime.now(),
      );

      emit(state.copyWith(
        isSending: false,
        messages: [...state.messages, aiMessage],
      ));
    } catch (e) {
      emit(state.copyWith(
        isSending: false,
        error: 'Không thể kết nối với AI',
      ));
    }
  }
}
