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

  @override
  Future<List<NotificationModel>> getNotifications(String userId) async =>
      notifications;

  @override
  Future<void> markAsRead(String notificationId) async {
    final error = markReadError;
    if (error != null) throw error;
  }
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
}
