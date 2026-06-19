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
    try {
      final messages = await _chatService.loadHistory(event.userId);
      if (messages.isNotEmpty) {
        emit(state.copyWith(isLoading: false, messages: messages));
      } else {
        final welcome = ChatMessageModel(
          id: const Uuid().v4(),
          userId: event.userId,
          content:
              'Chào bạn! Tôi là BigStyle Bot — trợ lý thời trang bigsize. '
              'Tôi có thể tư vấn outfit, chọn size, hay gợi ý sản phẩm phù hợp với bạn. '
              'Bạn cần giúp gì hôm nay? 🌸',
          isFromAi: true,
          createdAt: DateTime.now(),
        );
        emit(state.copyWith(isLoading: false, messages: [welcome]));
      }
    } catch (_) {
      emit(state.copyWith(isLoading: false, error: 'Không thể tải lịch sử'));
    }
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
      isTyping: true,
      messages: [...state.messages, userMessage],
    ));

    _chatService.saveMessage(userMessage);

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
        isTyping: false,
        messages: [...state.messages, aiMessage],
      ));

      _chatService.saveMessage(aiMessage);
    } catch (e) {
      emit(state.copyWith(
        isSending: false,
        isTyping: false,
        error: 'Không thể kết nối với AI',
      ));
    }
  }
}
