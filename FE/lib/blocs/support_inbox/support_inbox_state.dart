import 'package:equatable/equatable.dart';
import '../../models/support_conversation_model.dart';

class SupportInboxState extends Equatable {
  final List<SupportConversationModel> conversations;
  final bool isLoading;
  final String? error;

  const SupportInboxState({
    this.conversations = const [],
    this.isLoading = true,
    this.error,
  });

  /// Total unread across all conversations — drives the nav-tab badge.
  int get totalUnread =>
      conversations.fold(0, (sum, c) => sum + c.unreadForStaff);

  SupportInboxState copyWith({
    List<SupportConversationModel>? conversations,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SupportInboxState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [conversations, isLoading, error];
}
