import 'package:equatable/equatable.dart';
import '../../models/support_message_model.dart';

sealed class SupportChatEvent extends Equatable {
  const SupportChatEvent();

  @override
  List<Object?> get props => [];
}

/// Customer entry: resolve (get-or-create) the caller's own conversation, then
/// subscribe. Managers already hold a conversation id and use [SupportChatSubscribe].
class SupportChatOpenMine extends SupportChatEvent {
  const SupportChatOpenMine();
}

/// Subscribe the thread to a conversation's live message stream. Cancels any
/// prior subscription and marks the conversation read on open.
class SupportChatSubscribe extends SupportChatEvent {
  final String conversationId;
  const SupportChatSubscribe(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class SupportChatSend extends SupportChatEvent {
  final String senderId;
  final String content;
  const SupportChatSend({required this.senderId, required this.content});

  @override
  List<Object?> get props => [senderId, content];
}

/// Internal: a stream emission tagged with its conversation so late events from
/// a previous subscription can be dropped.
class SupportChatMessagesUpdated extends SupportChatEvent {
  final String conversationId;
  final List<SupportMessageModel>? messages; // null = stream error
  const SupportChatMessagesUpdated(this.conversationId, this.messages);

  @override
  List<Object?> get props => [conversationId, messages];
}
