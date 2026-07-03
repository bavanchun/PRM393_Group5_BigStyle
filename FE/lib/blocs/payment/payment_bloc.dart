import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'payment_event.dart';
import 'payment_state.dart';
import '../../services/payment_service.dart';
import '../../services/cart_service.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentService _paymentService;
  final CartService _cartService;

  StreamSubscription<bool>? _watchSub;
  // Realtime + polling can both fire "paid" before the subscription is
  // cancelled — this latch ensures clearCart runs exactly once per order.
  bool _paidHandled = false;
  String? _watchedUserId;

  PaymentBloc(this._paymentService, this._cartService)
      : super(const PaymentState()) {
    on<PaymentWatchStarted>(_onWatchStarted);
    on<PaymentStatusReceived>(_onStatusReceived);
    on<PaymentCheckRequested>(_onCheckRequested);
    on<PaymentWatchStopped>(_onWatchStopped);
  }

  Future<void> _onWatchStarted(
      PaymentWatchStarted event, Emitter<PaymentState> emit) async {
    await _watchSub?.cancel();
    _paidHandled = false;
    _watchedUserId = event.userId;
    emit(const PaymentState());

    _watchSub = _paymentService.watchPaymentStatus(event.orderId).listen(
          (paid) => add(PaymentStatusReceived(paid)),
        );
  }

  Future<void> _onStatusReceived(
      PaymentStatusReceived event, Emitter<PaymentState> emit) async {
    if (!event.paid || _paidHandled) return;
    _paidHandled = true;
    await _watchSub?.cancel();
    _watchSub = null;

    if (_watchedUserId != null) {
      try {
        await _cartService.clearCart(_watchedUserId!);
      } catch (_) {
        // Payment is confirmed regardless of cart-clear outcome — do not
        // block the success state on a non-critical cleanup failure.
      }
    }

    emit(state.copyWith(isPaid: true, isChecking: false));
  }

  Future<void> _onCheckRequested(
      PaymentCheckRequested event, Emitter<PaymentState> emit) async {
    if (_paidHandled) return;
    emit(state.copyWith(isChecking: true, error: null));
    try {
      final paid = await _paymentService.checkPaymentStatusOnce(event.orderId);
      if (paid) {
        add(const PaymentStatusReceived(true));
      } else {
        emit(state.copyWith(
          isChecking: false,
          error: 'Chưa nhận được thanh toán. Vui lòng thử lại sau ít phút.',
        ));
      }
    } catch (_) {
      emit(state.copyWith(
        isChecking: false,
        error: 'Không thể kiểm tra thanh toán. Vui lòng thử lại.',
      ));
    }
  }

  Future<void> _onWatchStopped(
      PaymentWatchStopped event, Emitter<PaymentState> emit) async {
    await _watchSub?.cancel();
    _watchSub = null;
    _watchedUserId = null;
  }

  @override
  Future<void> close() {
    _watchSub?.cancel();
    return super.close();
  }
}
