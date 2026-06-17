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

  const CheckoutPlaceOrder({
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.address,
    this.latitude,
    this.longitude,
    this.note,
  });

  @override
  List<Object?> get props =>
      [userId, items, subtotal, shippingFee, address, latitude, longitude, note];
}

class CheckoutCalculateShipping extends CheckoutEvent {
  final double? latitude;
  final double? longitude;
  const CheckoutCalculateShipping({this.latitude, this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];
}
