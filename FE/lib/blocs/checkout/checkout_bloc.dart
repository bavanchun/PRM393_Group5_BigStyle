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
      // Cart is cleared by CartBloc (CartClear) from the success listener in
      // checkout_screen — keeps CartBloc as the single owner of cart state so
      // the in-memory items/badge don't go stale after a direct DB clear here.

      emit(state.copyWith(
        isLoading: false,
        isSuccess: true,
        orderId: created.id,
        orderNumber: created.orderNumber,
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

}
