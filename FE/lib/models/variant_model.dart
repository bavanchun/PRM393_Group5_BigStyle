import 'package:equatable/equatable.dart';

/// Represents a product_variants row from the normalized DB schema.
class VariantModel extends Equatable {
  final String id;
  final String productId;
  final String size;
  final String color;
  final String colorHex;
  final int stockQty;
  final String? sku;

  const VariantModel({
    required this.id,
    required this.productId,
    required this.size,
    required this.color,
    required this.colorHex,
    required this.stockQty,
    this.sku,
  });

  factory VariantModel.fromMap(Map<String, dynamic> map) => VariantModel(
        id: map['id'] ?? '',
        productId: map['product_id'] ?? '',
        size: map['size'] ?? '',
        color: map['color'] ?? '',
        colorHex: map['color_hex'] ?? '',
        stockQty: map['stock_qty'] ?? 0,
        sku: map['sku'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'product_id': productId,
        'size': size,
        'color': color,
        'color_hex': colorHex,
        'stock_qty': stockQty,
        'sku': sku,
      };

  @override
  List<Object?> get props => [id, productId, size, color, colorHex, stockQty, sku];
}
