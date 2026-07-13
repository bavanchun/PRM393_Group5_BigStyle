import 'package:equatable/equatable.dart';
import '../../models/refund_request_model.dart';

abstract class RefundRequestEvent extends Equatable {
  const RefundRequestEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the (at most one) request for [orderId] — used by both the customer
/// and manager order-detail screens; RLS scopes what each role can see.
class RefundRequestLoadForOrder extends RefundRequestEvent {
  final String orderId;
  const RefundRequestLoadForOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class RefundRequestSubmit extends RefundRequestEvent {
  final String orderId;
  final String userId;
  final String reason;
  const RefundRequestSubmit({
    required this.orderId,
    required this.userId,
    required this.reason,
  });

  @override
  List<Object?> get props => [orderId, userId, reason];
}

class RefundRequestDecide extends RefundRequestEvent {
  final String requestId;
  // Carried explicitly (the caller already holds the full RefundRequestModel)
  // rather than read back from bloc state after the RPC await — state could
  // have moved on to a different order's load by the time that await
  // resolves, on an app-scoped bloc where events process concurrently.
  final String orderId;
  final RefundRequestStatus decision;
  final String? note;
  const RefundRequestDecide({
    required this.requestId,
    required this.orderId,
    required this.decision,
    this.note,
  });

  @override
  List<Object?> get props => [requestId, orderId, decision, note];
}

/// Manager order-list pending-indicator: the set of order ids with a
/// currently-pending request.
class RefundRequestLoadPendingOrderIds extends RefundRequestEvent {
  const RefundRequestLoadPendingOrderIds();
}
