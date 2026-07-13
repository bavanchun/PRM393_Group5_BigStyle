import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  final SupabaseClient _client;

  NotificationService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Emits a signal (no payload) whenever a `notifications` row for [userId]
  /// is inserted or updated. Callers refetch via [getNotifications] on each
  /// signal rather than merging partial payloads — mirrors the confirm-then-
  /// refetch pattern in `payment_service.dart`.
  Stream<void> subscribeToChanges(String userId) {
    late final RealtimeChannel channel;
    late final StreamController<void> controller;
    controller = StreamController<void>.broadcast(
      onListen: () {
        channel = _client
            .channel('notifications-$userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'notifications',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
              ),
              callback: (_) => controller.add(null),
            )
            .subscribe();
      },
      onCancel: () => _client.removeChannel(channel),
    );
    return controller.stream;
  }

  Future<List<NotificationModel>> getNotifications(String userId) async {
    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return data.map((e) => NotificationModel.fromMap(e)).toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<int> getUnreadCount(String userId) async {
    final data = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);
    return data.length;
  }
}
