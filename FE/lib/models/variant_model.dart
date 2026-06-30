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
  final String? heightRange;
  final String? weightRange;
  final String? bustRange;
  final String? waistRange;
  final String? hipsRange;
  final String? armRange;
  final String? thighRange;
  final String? shoulderRange;

  const VariantModel({
    required this.id,
    required this.productId,
    required this.size,
    required this.color,
    required this.colorHex,
    required this.stockQty,
    this.sku,
    this.heightRange,
    this.weightRange,
    this.bustRange,
    this.waistRange,
    this.hipsRange,
    this.armRange,
    this.thighRange,
    this.shoulderRange,
  });

  factory VariantModel.fromMap(Map<String, dynamic> map) => VariantModel(
        id: map['id'] ?? '',
        productId: map['product_id'] ?? '',
        size: map['size'] ?? '',
        color: map['color'] ?? '',
        colorHex: map['color_hex'] ?? '',
        stockQty: map['stock_qty'] ?? 0,
        sku: map['sku'],
        heightRange: map['height_range'],
        weightRange: map['weight_range'],
        bustRange: map['bust_range'],
        waistRange: map['waist_range'],
        hipsRange: map['hips_range'],
        armRange: map['arm_range'],
        thighRange: map['thigh_range'],
        shoulderRange: map['shoulder_range'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'product_id': productId,
        'size': size,
        'color': color,
        'color_hex': colorHex,
        'stock_qty': stockQty,
        'sku': sku,
        'height_range': heightRange,
        'weight_range': weightRange,
        'bust_range': bustRange,
        'waist_range': waistRange,
        'hips_range': hipsRange,
        'arm_range': armRange,
        'thigh_range': thighRange,
        'shoulder_range': shoulderRange,
      };

  @override
  List<Object?> get props => [
        id,
        productId,
        size,
        color,
        colorHex,
        stockQty,
        sku,
        heightRange,
        weightRange,
        bustRange,
        waistRange,
        hipsRange,
        armRange,
        thighRange,
        shoulderRange,
      ];
}
