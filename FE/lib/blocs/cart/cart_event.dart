import 'package:equatable/equatable.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class CartLoad extends CartEvent {
  final String userId;
  const CartLoad(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Add a variant to the user's cart. The bloc delegates to CartService which
/// handles get-or-create cart and quantity increment if already present.
class CartAddItem extends CartEvent {
  final String userId;
  final String variantId;
  final int quantity;

  const CartAddItem(this.userId, this.variantId, this.quantity);

  @override
  List<Object?> get props => [userId, variantId, quantity];
}

class CartUpdateQuantity extends CartEvent {
  final String cartId;
  final int quantity;
  const CartUpdateQuantity(this.cartId, this.quantity);

  @override
  List<Object?> get props => [cartId, quantity];
}

class CartRemoveItem extends CartEvent {
  final String cartId;
  const CartRemoveItem(this.cartId);

  @override
  List<Object?> get props => [cartId];
}

class CartClear extends CartEvent {
  final String userId;
  const CartClear(this.userId);

  @override
  List<Object?> get props => [userId];
}
