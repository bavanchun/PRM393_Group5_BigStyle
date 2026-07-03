import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'payment_event.dart';
import 'payment_state.dart';
import '../../services/payment_service.dart';
import '../../services/cart_service.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentService _paymentService;

  StreamSubscription<bool>? _watchSub;
  // Realtime + polling can both fire "paid" before the subscription is
  // cancelled — this latch ensures the isPaid state is emitted exactly once
  // per order (cart clearing is dispatched by the UI listener via CartBloc).
  bool _paidHandled = false;

  // CartService param kept for constructor-signature compatibility with
  // main.dart's wiring — cart clearing now lives solely in CartBloc (see
  // _onStatusReceived comment), so it's intentionally unused here.
  PaymentBloc(this._paymentService, CartService cartService)
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

    // Cart is cleared by CartBloc (CartClear) from the isPaid listener in
    // payment_qr_screen — keeps CartBloc as the single owner of cart state so
    // the in-memory items/badge don't go stale after a direct DB clear here.
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
  }

  @override
  Future<void> close() {
    _watchSub?.cancel();
    return super.close();
  }
}
