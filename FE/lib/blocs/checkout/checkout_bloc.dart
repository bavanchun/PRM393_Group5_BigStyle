import 'dart:math' show cos, sqrt, asin;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'checkout_event.dart';
import 'checkout_state.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/cart_service.dart';
import '../../services/payment_service.dart';

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final OrderService _orderService;
  final CartService _cartService;
  final PaymentService _paymentService;

  CheckoutBloc(this._orderService, this._cartService, this._paymentService)
      : super(const CheckoutState()) {
    on<CheckoutPlaceOrder>(_onPlaceOrder);
    on<CheckoutRetryPayment>(_onRetryPayment);
    on<CheckoutCalculateShipping>(_onCalculateShipping);
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
      final orderId = const Uuid().v4();
      final total = event.subtotal + event.shippingFee;

      // Build OrderItems from normalized CartItemModel fields
      final orderItems = event.items.map((item) => OrderItem(
            variantId: item.variantId,
            productName: item.product?.name ?? '',
            productImage: item.product?.images.isNotEmpty == true ? item.product!.images.first : null,
            size: item.variant?.size ?? '',
            color: item.variant?.color ?? '',
            quantity: item.quantity,
            unitPrice: item.product?.price ?? 0,
          )).toList();

      final order = OrderModel(
        id: orderId,
        userId: event.userId,
        items: orderItems,
        subtotal: event.subtotal,
        shippingFee: event.shippingFee,
        total: total,
        address: event.address,
        latitude: event.latitude,
        longitude: event.longitude,
        note: event.note,
        paymentMethod: event.paymentMethod,
        createdAt: DateTime.now(),
      );

      final created = await _orderService.createOrder(order);

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
      await _cartService.clearCart(event.userId);

      emit(state.copyWith(
        isLoading: false,
        isSuccess: true,
        orderId: created.id,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Đặt hàng thất bại. Vui lòng thử lại.',
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

  Future<void> _onCalculateShipping(
      CheckoutCalculateShipping event, Emitter<CheckoutState> emit) async {
    if (event.latitude == null || event.longitude == null) {
      emit(state.copyWith(shippingFee: 0));
      return;
    }

    const storeLat = 10.762622;
    const storeLng = 106.660172;

    final distance = _calculateDistance(
      storeLat,
      storeLng,
      event.latitude!,
      event.longitude!,
    );

    double fee;
    if (distance <= 2) {
      fee = 15000;
    } else if (distance <= 5) {
      fee = 25000;
    } else if (distance <= 10) {
      fee = 35000;
    } else if (distance <= 20) {
      fee = 50000;
    } else {
      fee = 70000;
    }

    emit(state.copyWith(shippingFee: fee));
  }

  static double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    const c = 6371;
    final a = 0.5 -
        (lat2 - lat1) * p / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return c * (2 * asin(sqrt(a)));
  }
}
