import 'package:equatable/equatable.dart';
import '../../models/chat_message_model.dart';

class ChatState extends Equatable {
  final bool isLoading;
  final bool isSending;
  final List<ChatMessageModel> messages;
  final String? error;

  const ChatState({
    this.isLoading = false,
    this.isSending = false,
    this.messages = const [],
    this.error,
  });

  ChatState copyWith({
    bool? isLoading,
    bool? isSending,
    List<ChatMessageModel>? messages,
    String? error,
  }) =>
      ChatState(
        isLoading: isLoading ?? this.isLoading,
        isSending: isSending ?? this.isSending,
        messages: messages ?? this.messages,
        error: error,
      );

  @override
  List<Object?> get props => [isLoading, isSending, messages, error];
}
