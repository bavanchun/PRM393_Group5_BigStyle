import 'dart:async';

import 'package:bigstyle_app/blocs/notification/notification_bloc.dart';
import 'package:bigstyle_app/blocs/notification/notification_event.dart';
import 'package:bigstyle_app/models/notification_model.dart';
import 'package:bigstyle_app/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeNotificationService extends NotificationService {
  FakeNotificationService()
    : super(client: SupabaseClient('http://localhost', 'anon-key'));

  List<NotificationModel> notifications = const [];
  Object? markReadError;
  final Map<String, StreamController<void>> _changeControllers = {};
  int cancelCount = 0;

  // Per-user override + a gate keyed to one userId, so a test can make that
  // user's fetch hang while a different user's fetch (no gate match)
  // proceeds and resolves first — reproducing the overlapping-load race.
  final Map<String, List<NotificationModel>> notificationsByUser = {};
  String? gatedUserId;
  Completer<void>? getNotificationsGate;

  StreamController<void> controllerFor(String userId) =>
      _changeControllers.putIfAbsent(
        userId,
        () => StreamController<void>.broadcast(onCancel: () => cancelCount++),
      );

  @override
  Future<List<NotificationModel>> getNotifications(String userId) async {
    if (userId == gatedUserId && getNotificationsGate != null) {
      await getNotificationsGate!.future;
    }
    return notificationsByUser[userId] ?? notifications;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final error = markReadError;
    if (error != null) throw error;
  }

  @override
  Stream<void> subscribeToChanges(String userId) => controllerFor(userId).stream;
}

NotificationModel _n(String id, {bool isRead = false}) => NotificationModel(
      id: id,
      userId: 'u1',
      title: 'T',
      body: 'B',
      isRead: isRead,
      createdAt: DateTime(2026, 7, 10),
    );

void main() {
  late FakeNotificationService service;

  setUp(() => service = FakeNotificationService());

  test('mark-read failure preserves the list and surfaces an error', () async {
    service.notifications = [_n('a'), _n('b')];
    service.markReadError = Exception('boom');
    final bloc = NotificationBloc(service);

    bloc.add(const NotificationLoad('u1'));
    await bloc.stream.firstWhere((s) => !s.isLoading);

    bloc.add(const NotificationMarkRead('a'));
    final state = await bloc.stream.firstWhere((s) => s.error != null);

    expect(state.error, isNotNull);
    expect(state.notifications.length, 2);
    // The list is untouched — 'a' is still unread because the write failed.
    expect(state.notifications.firstWhere((n) => n.id == 'a').isRead, isFalse);
    await bloc.close();
  });

  test('mark-read success marks the notification read', () async {
    service.notifications = [_n('a'), _n('b')];
    final bloc = NotificationBloc(service);

    bloc.add(const NotificationLoad('u1'));
    await bloc.stream.firstWhere((s) => !s.isLoading);

    bloc.add(const NotificationMarkRead('a'));
    final state = await bloc.stream.firstWhere(
      (s) => s.notifications.firstWhere((n) => n.id == 'a').isRead,
    );

    expect(state.unreadCount, 1);
    await bloc.close();
  });

  test('a realtime change refetches and updates unreadCount', () async {
    service.notifications = [_n('a', isRead: true)];
    final bloc = NotificationBloc(service);

    bloc.add(const NotificationLoad('u1'));
    await bloc.stream.firstWhere((s) => !s.isLoading);
    expect(bloc.state.unreadCount, 0);

    // Simulate a new notification row arriving server-side, then the
    // realtime signal that should trigger a refetch.
    service.notifications = [_n('a', isRead: true), _n('b')];
    service.controllerFor('u1').add(null);

    final state = await bloc.stream.firstWhere((s) => s.unreadCount == 1);
    expect(state.notifications.length, 2);
    await bloc.close();
  });

  test('loading a different user cancels the previous subscription',
      () async {
    final bloc = NotificationBloc(service);

    bloc.add(const NotificationLoad('u1'));
    await bloc.stream.firstWhere((s) => !s.isLoading);

    bloc.add(const NotificationLoad('u2'));
    await bloc.stream.firstWhere((s) => !s.isLoading);

    expect(service.cancelCount, 1);
    await bloc.close();
  });

  test('a late event from a replaced subscription is dropped', () async {
    final bloc = NotificationBloc(service);

    bloc.add(const NotificationLoad('u1'));
    await bloc.stream.firstWhere((s) => !s.isLoading);
    bloc.add(const NotificationLoad('u2'));
    await bloc.stream.firstWhere((s) => !s.isLoading);

    // u1's controller is retained by the fake even though the bloc has
    // moved on to u2 — a stray late event from it must not corrupt state.
    service.notifications = [_n('stale')];
    service.controllerFor('u1').add(null);
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.notifications, isEmpty);
    await bloc.close();
  });

  test('unsubscribe tears down the subscription and clears loaded state',
      () async {
    service.notifications = [_n('a')];
    final bloc = NotificationBloc(service);
    bloc.add(const NotificationLoad('u1'));
    await bloc.stream.firstWhere((s) => !s.isLoading);
    expect(bloc.state.notifications, isNotEmpty);

    await bloc.unsubscribe();
    // The cancellation is awaited directly above; the state-clear is
    // dispatched as an event (a bloc may only emit from within a handler),
    // so wait for the stream to reflect it rather than asserting instantly.
    await bloc.stream.firstWhere((s) => s.notifications.isEmpty);

    expect(service.cancelCount, 1);
    // Cleared, not left showing the previous account's notifications, so a
    // brief gap before the next account's first load can't leak content.
    expect(bloc.state.unreadCount, 0);
    await bloc.close();
  });

  test(
      'a superseded user\'s late-resolving load does not overwrite the '
      'current user\'s state (concurrent overlap, not just sequential)',
      () async {
    service.gatedUserId = 'u1';
    service.getNotificationsGate = Completer<void>();
    service.notificationsByUser['u1'] = [_n('stale-from-u1')];
    service.notificationsByUser['u2'] = [_n('fresh-from-u2')];
    final bloc = NotificationBloc(service);

    // u1's load starts and hangs mid-fetch (simulates network jitter).
    bloc.add(const NotificationLoad('u1'));
    await Future<void>.delayed(Duration.zero);

    // Before u1's fetch resolves, the user signs out and back in as u2 —
    // NotificationBloc.on<NotificationLoad> processes overlapping events
    // concurrently (bloc's default transformer), so u2's load runs while
    // u1's is still in flight, not queued behind it.
    bloc.add(const NotificationLoad('u2'));
    final afterU2 = await bloc.stream.firstWhere(
      (s) => !s.isLoading && s.notifications.isNotEmpty,
    );
    expect(afterU2.notifications.single.id, 'fresh-from-u2');

    // Now let u1's stale fetch finally resolve. It must be dropped, not
    // clobber u2's already-current state.
    service.getNotificationsGate!.complete();
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.notifications.single.id, 'fresh-from-u2');
    await bloc.close();
  });
}
