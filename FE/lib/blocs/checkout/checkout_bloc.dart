import 'package:flutter_bloc/flutter_bloc.dart';
import 'checkout_event.dart';
import 'checkout_state.dart';
import '../../services/order_service.dart';
import '../../services/cart_service.dart';
import '../../services/payment_service.dart';

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final OrderService _orderService;
  final PaymentService _paymentService;

  // CartService param kept for constructor-signature compatibility with
  // main.dart's wiring — cart clearing now lives solely in CartBloc (see
  // _onPlaceOrder comment), so it's intentionally unused here.
  CheckoutBloc(
    this._orderService,
    CartService cartService,
    this._paymentService,
  ) : super(const CheckoutState()) {
    on<CheckoutPlaceOrder>(_onPlaceOrder);
    on<CheckoutRetryPayment>(_onRetryPayment);
  }

  Future<void> _onPlaceOrder(
      CheckoutPlaceOrder event, Emitter<CheckoutState> emit) async {
    // CheckoutBloc is app-scoped (provided once in main.dart) — reset the
    // outcome flags so a stale isSuccess/awaitingPayment from a previous
    // order never double-fires the screen listener on this new order.
    // orderId/orderNumber get overwritten below once the new order exists;
    // they are harmless to leave stale during the brief isLoading window
    // since the listener branches only on isSuccess/awaitingPayment.
    emit(state.copyWith(
      isLoading: true,
      isSuccess: false,
      awaitingPayment: false,
      error: null,
    ));
    try {
      // shipping_address jsonb payload — mirrors the shape create_order
      // expects; latitude/longitude are optional.
      final shippingAddress = <String, dynamic>{
        'address': event.address,
        if (event.latitude != null) 'latitude': event.latitude,
        if (event.longitude != null) 'longitude': event.longitude,
      };

      // Authoritative write path: create_order (SECURITY DEFINER) recomputes
      // subtotal from real variant prices and re-derives the discount
      // server-side — the client no longer sends/trusts any money fields.
      final created = await _orderService.createOrderViaRpc(
        items: event.items,
        shippingAddress: shippingAddress,
        shippingFee: event.shippingFee,
        paymentMethod: event.paymentMethod,
        notes: event.note,
        promoCode: event.promoCode,
      );
      final total = created.total;

      if (event.paymentMethod == 'bank_transfer') {
        await _createPendingBankPayment(
          emit: emit,
          orderId: created.id,
          userId: event.userId,
          orderNumber: created.orderNumber,
          total: total,
        );
        return;
      }

      // COD: keep the original behavior — payments(cod,pending) row +
      // immediate cart clear + success screen.
      await _paymentService.createPayment(
        orderId: created.id,
        userId: event.userId,
        method: 'cod',
        amount: total,
      );
      // Cart: individual items removed by checkout_screen success listener
      // so unselected items survive.

      emit(state.copyWith(
        isLoading: false,
        isSuccess: true,
        orderId: created.id,
        orderNumber: created.orderNumber,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Đặt hàng thất bại: $e',
      ));
    }
  }

  /// Order already exists (createOrder succeeded, or a prior createPayment
  /// attempt failed) — only (re)creates the pending payments row. Safe to
  /// retry: the unique partial index on payments(order_id) where
  /// status='pending' rejects duplicates instead of creating extras.
  Future<void> _onRetryPayment(
      CheckoutRetryPayment event, Emitter<CheckoutState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    await _createPendingBankPayment(
      emit: emit,
      orderId: event.orderId,
      userId: event.userId,
      orderNumber: event.orderNumber,
      total: event.total,
    );
  }

  Future<void> _createPendingBankPayment({
    required Emitter<CheckoutState> emit,
    required String orderId,
    required String userId,
    required String? orderNumber,
    required double total,
  }) async {
    try {
      await _paymentService.createPayment(
        orderId: orderId,
        userId: userId,
        method: 'bank_transfer',
        amount: total,
      );
      // Cart stays intact — only cleared once PaymentBloc confirms paid.
      emit(state.copyWith(
        isLoading: false,
        awaitingPayment: true,
        orderId: orderId,
        orderNumber: orderNumber,
        total: total,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        orderId: orderId,
        orderNumber: orderNumber,
        total: total,
        error: 'Tạo yêu cầu thanh toán thất bại. Vui lòng thử lại.',
      ));
    }
  }

}
