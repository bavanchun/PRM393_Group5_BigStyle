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

/// Fired internally when the realtime subscription observes a change.
/// Carries [userId] so a late event from a just-replaced subscription
/// (account switch) can be dropped instead of corrupting the new user's state.
class NotificationRealtimeReceived extends NotificationEvent {
  final String userId;
  const NotificationRealtimeReceived(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Fired internally by [NotificationBloc.unsubscribe] to reset state through
/// the normal event pipeline (a bloc may only emit from within a handler).
class NotificationCleared extends NotificationEvent {
  const NotificationCleared();
}

class NotificationMarkAllRead extends NotificationEvent {
  final String userId;
  const NotificationMarkAllRead(this.userId);

  @override
  List<Object?> get props => [userId];
}
