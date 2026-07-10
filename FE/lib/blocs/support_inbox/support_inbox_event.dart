import 'package:equatable/equatable.dart';
import '../../models/support_conversation_model.dart';

sealed class SupportInboxEvent extends Equatable {
  const SupportInboxEvent();

  @override
  List<Object?> get props => [];
}

/// Start (or restart) the live inbox subscription.
class SupportInboxSubscribe extends SupportInboxEvent {
  const SupportInboxSubscribe();
}

/// Internal: a new inbox snapshot from the stream.
class SupportInboxUpdated extends SupportInboxEvent {
  final List<SupportConversationModel>? conversations; // null = stream error
  const SupportInboxUpdated(this.conversations);

  @override
  List<Object?> get props => [conversations];
}
