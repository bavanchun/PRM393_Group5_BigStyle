import 'package:equatable/equatable.dart';
import '../../models/cart_item_model.dart';

class CartState extends Equatable {
  final bool isLoading;
  final List<CartItemModel> items;
  final String? error;

  const CartState({
    this.isLoading = false,
    this.items = const [],
    this.error,
  });

  int get itemCount => items.length;
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  CartState copyWith({
    bool? isLoading,
    List<CartItemModel>? items,
    String? error,
  }) =>
      CartState(
        isLoading: isLoading ?? this.isLoading,
        items: items ?? this.items,
        error: error,
      );

  @override
  List<Object?> get props => [isLoading, items, error];
}
