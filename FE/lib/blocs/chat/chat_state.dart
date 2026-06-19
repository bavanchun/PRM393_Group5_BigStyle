import 'package:equatable/equatable.dart';
import '../../models/chat_message_model.dart';

class ChatState extends Equatable {
  final bool isLoading;
  final bool isSending;
  final bool isTyping;
  final List<ChatMessageModel> messages;
  final String? error;

  const ChatState({
    this.isLoading = false,
    this.isSending = false,
    this.isTyping = false,
    this.messages = const [],
    this.error,
  });

  ChatState copyWith({
    bool? isLoading,
    bool? isSending,
    bool? isTyping,
    List<ChatMessageModel>? messages,
    String? error,
  }) =>
      ChatState(
        isLoading: isLoading ?? this.isLoading,
        isSending: isSending ?? this.isSending,
        isTyping: isTyping ?? this.isTyping,
        messages: messages ?? this.messages,
        error: error,
      );

  @override
  List<Object?> get props =>
      [isLoading, isSending, isTyping, messages, error];
}
