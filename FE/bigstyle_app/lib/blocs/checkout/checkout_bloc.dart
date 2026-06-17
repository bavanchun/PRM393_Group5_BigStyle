import 'dart:math' show cos, sqrt, asin;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'checkout_event.dart';
import 'checkout_state.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/cart_service.dart';

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final OrderService _orderService;
  final CartService _cartService;

  CheckoutBloc(this._orderService, this._cartService)
      : super(const CheckoutState()) {
    on<CheckoutPlaceOrder>(_onPlaceOrder);
    on<CheckoutCalculateShipping>(_onCalculateShipping);
  }

  Future<void> _onPlaceOrder(
      CheckoutPlaceOrder event, Emitter<CheckoutState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final orderId = const Uuid().v4();
      final total = event.subtotal + event.shippingFee;
      final order = OrderModel(
        id: orderId,
        userId: event.userId,
        items: event.items.map((item) => OrderItem(
              productId: item.productId,
              size: item.size,
              quantity: item.quantity,
              price: item.product?.price ?? 0,
            )).toList(),
        subtotal: event.subtotal,
        shippingFee: event.shippingFee,
        total: total,
        address: event.address,
        latitude: event.latitude,
        longitude: event.longitude,
        note: event.note,
        createdAt: DateTime.now(),
      );

      await _orderService.createOrder(order);
      await _cartService.clearCart(event.userId);

      emit(state.copyWith(
        isLoading: false,
        isSuccess: true,
        orderId: orderId,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Đặt hàng thất bại. Vui lòng thử lại.',
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
