import 'package:equatable/equatable.dart';
import '../../models/notification_model.dart';

class NotificationState extends Equatable {
  final bool isLoading;
  final List<NotificationModel> notifications;
  final int unreadCount;
  final String? error;

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.unreadCount = 0,
    this.error,
  });

  NotificationState copyWith({
    bool? isLoading,
    List<NotificationModel>? notifications,
    int? unreadCount,
    String? error,
  }) =>
      NotificationState(
        isLoading: isLoading ?? this.isLoading,
        notifications: notifications ?? this.notifications,
        unreadCount: unreadCount ?? this.unreadCount,
        error: error,
      );

  @override
  List<Object?> get props =>
      [isLoading, notifications, unreadCount, error];
}
