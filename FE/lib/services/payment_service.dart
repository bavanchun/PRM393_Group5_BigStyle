import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

/// Handles the `payments` table: creating a pending row at checkout and
/// watching for it to flip to 'success' (SePay webhook writes that row).
class PaymentService {
  final SupabaseClient _client;

  PaymentService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Inserts a pending payments row for [orderId]. A partial unique index on
  /// `payments(order_id) where status='pending'` makes this call idempotent —
  /// retrying after a failed createOrder+createPayment sequence is safe.
  Future<void> createPayment({
    required String orderId,
    required String userId,
    required String method,
    required double amount,
  }) async {
    await _client.from('payments').insert({
      'order_id': orderId,
      'user_id': userId,
      'method': method,
      'amount': amount,
      'status': 'pending',
    });
  }

  /// Emits `true` once when the most recent payment row for [orderId]
  /// reaches status 'success'. Combines a Realtime subscription (instant) with
  /// a 3s polling fallback (in case the socket misses the event). Callers own
  /// cancelling the returned subscription — call [dispose] on the returned
  /// controller's subscription (StreamSubscription.cancel) to stop both.
  Stream<bool> watchPaymentStatus(String orderId) {
    late final StreamController<bool> controller;
    RealtimeChannel? channel;
    Timer? pollTimer;
    var closed = false;

    Future<void> checkOnce() async {
      if (closed) return;
      try {
        final row = await _client
            .from('payments')
            .select('status')
            .eq('order_id', orderId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (closed) return;
        if (row != null && row['status'] == 'success') {
          controller.add(true);
        }
      } catch (_) {
        // Swallow transient network/poll errors — next tick or realtime event retries.
      }
    }

    void stop() {
      if (closed) return;
      closed = true;
      pollTimer?.cancel();
      if (channel != null) {
        _client.removeChannel(channel!);
      }
    }

    controller = StreamController<bool>(
      onListen: () {
        channel = _client
            .channel('payments-order-$orderId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'payments',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'order_id',
                value: orderId,
              ),
              callback: (payload) {
                final newRow = payload.newRecord;
                if (newRow['status'] == 'success') {
                  controller.add(true);
                }
              },
            )
            .subscribe();

        pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => checkOnce());
        // Fire an immediate check too, so a missed webhook right before the
        // first poll tick doesn't cost the user a full 3s.
        checkOnce();
      },
      onCancel: stop,
    );

    return controller.stream;
  }

  /// Runs a single on-demand status check — used by the "Kiểm tra thanh toán"
  /// button so users don't have to wait for the next poll tick.
  Future<bool> checkPaymentStatusOnce(String orderId) async {
    final row = await _client
        .from('payments')
        .select('status')
        .eq('order_id', orderId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row != null && row['status'] == 'success';
  }

  /// Builds the SePay VietQR image URL. `amount` MUST be an integer — VND has
  /// no decimals and SePay expects a bare integer (a raw double interpolates
  /// as "150000.0" and breaks the QR).
  String buildQrUrl(double total, String orderNumber) {
    final acc = AppConfig.sepayAcc;
    final bank = AppConfig.sepayBank;
    assert(
      acc.isNotEmpty && bank.isNotEmpty,
      'SEPAY_ACC/SEPAY_BANK missing in .env — QR image will fail to load.',
    );
    return 'https://qr.sepay.vn/img?acc=$acc&bank=$bank&amount=${total.toInt()}&des=$orderNumber&template=compact';
  }
}
