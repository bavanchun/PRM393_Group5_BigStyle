import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/refund_request_service.dart';
import 'refund_request_event.dart';
import 'refund_request_state.dart';

class RefundRequestBloc extends Bloc<RefundRequestEvent, RefundRequestState> {
  final RefundRequestService _service;

  // RefundRequestBloc is app-scoped (one instance backs both the customer's
  // and manager's order-detail screens) and bloc's default event transformer
  // runs same-type handlers concurrently, not queued. Without this guard, a
  // slow load for order A resolving after a newer load for order B has
  // already completed would silently overwrite currentRequest with A's data
  // while a still-mounted screen for B is displaying it — the same class of
  // bug NotificationBloc had (see its _subscribedUserId).
  String? _requestedOrderId;

  RefundRequestBloc(this._service) : super(const RefundRequestState()) {
    on<RefundRequestLoadForOrder>(_onLoadForOrder);
    on<RefundRequestSubmit>(_onSubmit);
    on<RefundRequestDecide>(_onDecide);
    on<RefundRequestLoadPendingOrderIds>(_onLoadPendingOrderIds);
  }

  Future<void> _onLoadForOrder(
    RefundRequestLoadForOrder event,
    Emitter<RefundRequestState> emit,
  ) async {
    _requestedOrderId = event.orderId;
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final request = await _service.getForOrder(event.orderId);
      if (event.orderId != _requestedOrderId) return;
      emit(
        state.copyWith(
          isLoading: false,
          currentRequest: request,
          clearCurrentRequest: request == null,
        ),
      );
    } catch (_) {
      if (event.orderId != _requestedOrderId) return;
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Tải yêu cầu hoàn tiền thất bại',
        ),
      );
    }
  }

  Future<void> _onSubmit(
    RefundRequestSubmit event,
    Emitter<RefundRequestState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true, error: null));
    try {
      await _service.submit(
        orderId: event.orderId,
        userId: event.userId,
        reason: event.reason,
      );
      // Same staleness concern as _onDecide: if the customer has since
      // navigated to a different order's screen, don't let this submit's
      // late resolution overwrite that order's currentRequest.
      final stillCurrent = event.orderId == _requestedOrderId;
      final request = stillCurrent
          ? await _service.getForOrder(event.orderId)
          : null;
      emit(
        state.copyWith(
          isProcessing: false,
          currentRequest: stillCurrent ? request : state.currentRequest,
        ),
      );
    } catch (_) {
      // Almost always the server-side eligibility gate (order not delivered,
      // outside the 7-day window, or a request already exists) — the button
      // is hidden pre-emptively for the common case, so this is a fallback.
      emit(
        state.copyWith(
          isProcessing: false,
          error:
              'Không thể gửi yêu cầu hoàn tiền. Đơn có thể không đủ điều kiện.',
        ),
      );
    }
  }

  Future<void> _onDecide(
    RefundRequestDecide event,
    Emitter<RefundRequestState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true, error: null));
    try {
      await _service.decide(
        requestId: event.requestId,
        decision: event.decision,
        note: event.note,
      );
      final updatedPending = Set<String>.from(state.pendingOrderIds)
        ..remove(event.orderId);
      // event.orderId, not state.currentRequest?.orderId — a different
      // order's load may have taken over the screen this bloc instance
      // backs by the time this await resolves (see _onLoadForOrder's
      // comment). isProcessing still resets either way; only the
      // currentRequest refetch/emit is skipped when stale, so a decision
      // sheet dispatched for A doesn't clobber a since-loaded order B.
      final stillCurrent = event.orderId == _requestedOrderId;
      final request = stillCurrent
          ? await _service.getForOrder(event.orderId)
          : null;
      emit(
        state.copyWith(
          isProcessing: false,
          currentRequest: stillCurrent ? request : state.currentRequest,
          pendingOrderIds: updatedPending,
        ),
      );
    } catch (_) {
      // Always reset isProcessing (regardless of staleness) so a sheet
      // dispatched for a now-superseded order doesn't leave the UI stuck
      // showing a spinner forever.
      emit(
        state.copyWith(isProcessing: false, error: 'Xử lý yêu cầu thất bại'),
      );
    }
  }

  Future<void> _onLoadPendingOrderIds(
    RefundRequestLoadPendingOrderIds event,
    Emitter<RefundRequestState> emit,
  ) async {
    try {
      final ids = await _service.getPendingOrderIds();
      emit(state.copyWith(pendingOrderIds: ids));
    } catch (_) {
      // Silent — a missing pending-indicator badge isn't worth a user-facing
      // error; the manager can still see/decide requests from the detail screen.
    }
  }
}
