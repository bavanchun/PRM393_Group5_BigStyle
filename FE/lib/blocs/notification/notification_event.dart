import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class NotificationLoad extends NotificationEvent {
  final String userId;
  const NotificationLoad(this.userId);

  @override
  List<Object?> get props => [userId];
}

class NotificationMarkRead extends NotificationEvent {
  final String notificationId;
  const NotificationMarkRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class NotificationMarkAllRead extends NotificationEvent {
  final String userId;
  const NotificationMarkAllRead(this.userId);

  @override
  List<Object?> get props => [userId];
}
