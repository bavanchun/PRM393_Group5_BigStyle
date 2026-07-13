import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'notification_event.dart';
import 'notification_state.dart';
import '../../services/notification_service.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationService _notificationService;

  // NotificationBloc is app-scoped (created once in main.dart), so unlike a
  // screen-scoped bloc it can't rely on close() to end the subscription when
  // a user signs out — callers must invoke unsubscribe() explicitly.
  StreamSubscription<void>? _realtimeSubscription;
  String? _subscribedUserId;

  NotificationBloc(this._notificationService)
    : super(const NotificationState()) {
    on<NotificationLoad>(_onLoad);
    on<NotificationMarkRead>(_onMarkRead);
    on<NotificationRealtimeReceived>(_onRealtimeReceived);
    on<NotificationCleared>((_, emit) => emit(const NotificationState()));
  }

  Future<void> _onLoad(
    NotificationLoad event,
    Emitter<NotificationState> emit,
  ) async {
    if (_subscribedUserId != event.userId) {
      await _realtimeSubscription?.cancel();
      _subscribedUserId = event.userId;
      _realtimeSubscription = _notificationService
          .subscribeToChanges(event.userId)
          .listen((_) => add(NotificationRealtimeReceived(event.userId)));
    }
    emit(state.copyWith(isLoading: true));
    try {
      final notifications = await _notificationService.getNotifications(
        event.userId,
      );
      // Drop a late resolution from a load that's since been superseded by
      // a different user's NotificationLoad (e.g. rapid sign-out/sign-in via
      // the debug test-login buttons) — otherwise stale data from the
      // previous account could overwrite the new account's freshly-loaded
      // state, since the bloc processes same-type events concurrently.
      if (event.userId != _subscribedUserId) return;
      final unreadCount = notifications.where((n) => !n.isRead).length;
      emit(
        state.copyWith(
          isLoading: false,
          notifications: notifications,
          unreadCount: unreadCount,
        ),
      );
    } catch (e) {
      if (event.userId != _subscribedUserId) return;
      emit(state.copyWith(isLoading: false, error: 'Tải thông báo thất bại'));
    }
  }

  Future<void> _onRealtimeReceived(
    NotificationRealtimeReceived event,
    Emitter<NotificationState> emit,
  ) async {
    // Drop a late event from a subscription that's since been replaced
    // (e.g. a different account signed in right after this one fired).
    if (event.userId != _subscribedUserId) return;
    try {
      final notifications = await _notificationService.getNotifications(
        event.userId,
      );
      final unreadCount = notifications.where((n) => !n.isRead).length;
      emit(
        state.copyWith(notifications: notifications, unreadCount: unreadCount),
      );
    } catch (_) {
      // Silent refresh — keep showing the last-known-good list; the next
      // successful realtime event (or a manual NotificationLoad) corrects it.
    }
  }

  /// Tears down the realtime subscription and clears the loaded list. Call
  /// on sign-out — the bloc itself stays alive (app-scoped) for the next
  /// sign-in, and clearing here (rather than leaving stale data) closes the
  /// gap between sign-out and the next account's first successful load.
  Future<void> unsubscribe() async {
    await _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
    _subscribedUserId = null;
    add(const NotificationCleared());
  }

  @override
  Future<void> close() async {
    await _realtimeSubscription?.cancel();
    return super.close();
  }

  Future<void> _onMarkRead(
    NotificationMarkRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationService.markAsRead(event.notificationId);
      final notifications = state.notifications.map((n) {
        if (n.id == event.notificationId) return n.copyWith(isRead: true);
        return n;
      }).toList();
      final unreadCount = notifications.where((n) => !n.isRead).length;
      emit(
        state.copyWith(notifications: notifications, unreadCount: unreadCount),
      );
    } catch (_) {
      // Keep the current list; surface the failure like the load path does.
      emit(state.copyWith(error: 'Đánh dấu đã đọc thất bại'));
    }
  }
}
