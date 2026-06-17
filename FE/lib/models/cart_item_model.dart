import 'package:equatable/equatable.dart';
import 'product_model.dart';

class CartItemModel extends Equatable {
  final String id;
  final String productId;
  final ProductModel? product;
  final String size;
  final int quantity;
  final DateTime addedAt;

  const CartItemModel({
    required this.id,
    required this.productId,
    this.product,
    required this.size,
    this.quantity = 1,
    required this.addedAt,
  });

  double get totalPrice => (product?.price ?? 0) * quantity;

  Map<String, dynamic> toMap() => {
        'id': id,
        'product_id': productId,
        'size': size,
        'quantity': quantity,
        'added_at': addedAt.toIso8601String(),
      };

  factory CartItemModel.fromMap(Map<String, dynamic> map) => CartItemModel(
        id: map['id'] ?? '',
        productId: map['product_id'] ?? '',
        product: map['product'] != null
            ? ProductModel.fromMap(map['product'])
            : null,
        size: map['size'] ?? '',
        quantity: map['quantity'] ?? 1,
        addedAt: DateTime.tryParse(map['added_at'] ?? '') ?? DateTime.now(),
      );

  CartItemModel copyWith({int? quantity, ProductModel? product}) =>
      CartItemModel(
        id: id,
        productId: productId,
        product: product ?? this.product,
        size: size,
        quantity: quantity ?? this.quantity,
        addedAt: addedAt,
      );

  @override
  List<Object?> get props =>
      [id, productId, product, size, quantity, addedAt];
}
