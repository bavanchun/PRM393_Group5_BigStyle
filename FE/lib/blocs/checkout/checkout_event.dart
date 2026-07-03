import 'package:equatable/equatable.dart';
import '../../models/cart_item_model.dart';

abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

class CheckoutPlaceOrder extends CheckoutEvent {
  final String userId;
  final List<CartItemModel> items;
  final double subtotal;
  final double shippingFee;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? note;
  // 'cod' | 'bank_transfer'
  final String paymentMethod;

  const CheckoutPlaceOrder({
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.address,
    this.latitude,
    this.longitude,
    this.note,
    this.paymentMethod = 'cod',
  });

  @override
  List<Object?> get props => [
        userId,
        items,
        subtotal,
        shippingFee,
        address,
        latitude,
        longitude,
        note,
        paymentMethod,
      ];
}

/// Retries creating the pending payments row for an order that was already
/// created (createOrder succeeded, createPayment failed). orderId is a
/// client-generated UUID, so this never re-inserts the order — only the
/// payments row, which is safe to retry (unique partial index on pending).
class CheckoutRetryPayment extends CheckoutEvent {
  final String orderId;
  final String userId;
  final String? orderNumber;
  final double total;

  const CheckoutRetryPayment({
    required this.orderId,
    required this.userId,
    required this.orderNumber,
    required this.total,
  });

  @override
  List<Object?> get props => [orderId, userId, orderNumber, total];
}
