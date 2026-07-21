import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/refund_request_model.dart';

class RefundRequestService {
  final SupabaseClient _client;

  RefundRequestService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// The request for a given order (at most one — order_id is unique), or
  /// null if the customer hasn't requested a refund on it.
  Future<RefundRequestModel?> getForOrder(String orderId) async {
    final data = await _client
        .from('refund_requests')
        .select()
        .eq('order_id', orderId)
        .maybeSingle();
    return data != null ? RefundRequestModel.fromMap(data) : null;
  }

  /// Order ids with a currently-pending request — manager order-list badge.
  Future<Set<String>> getPendingOrderIds() async {
    final data = await _client
        .from('refund_requests')
        .select('order_id')
        .eq('status', 'pending');
    return data.map((e) => e['order_id'] as String).toSet();
  }

  /// Eligibility (delivered, within 7 days, no existing request) is enforced
  /// server-side by RLS — a rejected insert here means one of those didn't
  /// hold, not a client bug.
  Future<void> submit({
    required String orderId,
    required String userId,
    required String reason,
  }) async {
    await _client.from('refund_requests').insert({
      'order_id': orderId,
      'user_id': userId,
      'reason': reason,
    });
  }

  /// Manager decision via the `decide_refund_request` RPC — atomically
  /// updates the request, and on approval the order's status (which the
  /// existing `on_order_status_change` trigger then notifies the customer
  /// about); the RPC also owns the reject-path notification.
  Future<void> decide({
    required String requestId,
    required RefundRequestStatus decision,
    String? note,
  }) async {
    await _client.rpc(
      'decide_refund_request',
      params: {
        'p_request_id': requestId,
        'p_decision': decision.name,
        'p_note': note,
      },
    );
  }
}
