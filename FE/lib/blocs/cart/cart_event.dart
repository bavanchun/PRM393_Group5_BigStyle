import 'package:equatable/equatable.dart';
import '../../models/cart_item_model.dart';

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

class CartAddItem extends CartEvent {
  final CartItemModel item;
  const CartAddItem(this.item);

  @override
  List<Object?> get props => [item];
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
