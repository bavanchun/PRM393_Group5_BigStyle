import 'package:equatable/equatable.dart';
import 'product_model.dart';
import 'variant_model.dart';

/// Maps a cart_items row joined as:
/// *, variant:product_variants(*, product:products(*, category:categories(*)))
class CartItemModel extends Equatable {
  final String id;
  final String variantId;
  final int quantity;
  final DateTime addedAt;
  final ProductModel? product;
  final VariantModel? variant;

  const CartItemModel({
    required this.id,
    required this.variantId,
    this.quantity = 1,
    required this.addedAt,
    this.product,
    this.variant,
  });

  // --- UI compatibility accessors ---

  /// The product id, derived from the loaded product.
  String get productId => product?.id ?? '';

  /// The size from the resolved variant.
  String get size => variant?.size ?? '';

  /// Line-item total using the resolved product price.
  double get totalPrice => (product?.price ?? 0) * quantity;

  // --- Persistence ---

  /// Minimal map for insert into cart_items; cart_id is set by the service.
  Map<String, dynamic> toMap() => {
        'variant_id': variantId,
        'quantity': quantity,
      };

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    // variant is a joined product_variants row
    final variantMap = map['variant'] as Map<String, dynamic>?;

    // product is nested inside variant
    ProductModel? product;
    VariantModel? variant;

    if (variantMap != null) {
      final productMap = variantMap['product'] as Map<String, dynamic>?;
      product = productMap != null ? ProductModel.fromMap(productMap) : null;
      variant = VariantModel.fromMap(variantMap);
    }

    return CartItemModel(
      id: map['id'] ?? '',
      variantId: map['variant_id'] ?? '',
      quantity: map['quantity'] ?? 1,
      addedAt: DateTime.tryParse(map['added_at'] ?? '') ?? DateTime.now(),
      product: product,
      variant: variant,
    );
  }

  CartItemModel copyWith({int? quantity, ProductModel? product, VariantModel? variant}) =>
      CartItemModel(
        id: id,
        variantId: variantId,
        quantity: quantity ?? this.quantity,
        addedAt: addedAt,
        product: product ?? this.product,
        variant: variant ?? this.variant,
      );

  @override
  List<Object?> get props => [id, variantId, quantity, addedAt, product, variant];
}
