import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatSendMessage extends ChatEvent {
  final String userId;
  final String content;
  const ChatSendMessage(this.userId, this.content);

  @override
  List<Object?> get props => [userId, content];
}

class ChatLoadHistory extends ChatEvent {
  final String userId;
  const ChatLoadHistory(this.userId);

  @override
  List<Object?> get props => [userId];
}
