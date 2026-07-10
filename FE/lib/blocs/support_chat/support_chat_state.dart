import 'package:equatable/equatable.dart';
import '../../models/support_message_model.dart';

class SupportChatState extends Equatable {
  final String? conversationId;
  final List<SupportMessageModel> messages;
  final bool isLoading;
  final String? error;

  const SupportChatState({
    this.conversationId,
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  SupportChatState copyWith({
    String? conversationId,
    List<SupportMessageModel>? messages,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SupportChatState(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [conversationId, messages, isLoading, error];
}
