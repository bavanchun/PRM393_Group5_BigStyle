import 'package:flutter_bloc/flutter_bloc.dart';
import 'notification_event.dart';
import 'notification_state.dart';
import '../../services/notification_service.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationService _notificationService;

  NotificationBloc(this._notificationService)
      : super(const NotificationState()) {
    on<NotificationLoad>(_onLoad);
    on<NotificationMarkRead>(_onMarkRead);
  }

  Future<void> _onLoad(
      NotificationLoad event, Emitter<NotificationState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final notifications =
          await _notificationService.getNotifications(event.userId);
      final unreadCount = notifications.where((n) => !n.isRead).length;
      emit(state.copyWith(
        isLoading: false,
        notifications: notifications,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      emit(state.copyWith(
          isLoading: false, error: 'Tải thông báo thất bại'));
    }
  }

  Future<void> _onMarkRead(
      NotificationMarkRead event, Emitter<NotificationState> emit) async {
    try {
      await _notificationService.markAsRead(event.notificationId);
      final notifications = state.notifications.map((n) {
        if (n.id == event.notificationId) return n.copyWith(isRead: true);
        return n;
      }).toList();
      final unreadCount = notifications.where((n) => !n.isRead).length;
      emit(state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
      ));
    } catch (_) {}
  }
}
