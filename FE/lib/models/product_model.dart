import 'package:equatable/equatable.dart';
import 'category_model.dart';
import 'variant_model.dart';

/// Canonical size ordering for Vietnamese bigsize apparel.
const _kSizeOrder = ['M', 'L', 'XL', '2XL', '3XL', '4XL', '5XL'];

class ProductModel extends Equatable {
  final String id;
  final String name;
  final String description;
  // price = sale_price ?? base_price (resolved in fromMap)
  final double price;
  // originalPrice = base_price when sale_price is present (shows strikethrough)
  final double? originalPrice;
  final List<String> images;
  final String? categoryId;
  final CategoryModel? category;
  final double? rating;
  final int reviewCount;
  final bool isFeatured;
  final bool isActive;
  final String? material;
  final String? elasticity;
  final String? storeId;
  final DateTime createdAt;
  // Variants loaded via product_variants(*) join
  final List<VariantModel> variants;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.images,
    this.categoryId,
    this.category,
    this.rating,
    this.reviewCount = 0,
    this.isFeatured = false,
    this.isActive = true,
    this.material,
    this.elasticity,
    this.storeId,
    required this.createdAt,
    this.variants = const [],
  });

  /// Distinct sizes from variants in canonical order.
  List<String> get sizes {
    final variantSizes = variants.map((v) => v.size).toSet();
    final ordered = _kSizeOrder.where(variantSizes.contains).toList();
    // Append any non-standard sizes not in canonical list
    final extras = variantSizes.where((s) => !_kSizeOrder.contains(s)).toList()..sort();
    return [...ordered, ...extras];
  }

  /// Total stock across all variants.
  int get stock => variants.fold(0, (sum, v) => sum + v.stockQty);

  double get discountPercent {
    if (originalPrice == null || originalPrice! <= price) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
  }

  bool get hasDiscount => discountPercent > 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'base_price': originalPrice ?? price,
        'sale_price': originalPrice != null ? price : null,
        'images': images,
        'category_id': categoryId,
        'avg_rating': rating,
        'review_count': reviewCount,
        'is_featured': isFeatured,
        'is_active': isActive,
        'material': material,
        'elasticity': elasticity,
        'store_id': storeId,
        'created_at': createdAt.toIso8601String(),
      };

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    final basePrice = (map['base_price'] ?? 0).toDouble();
    final salePrice = map['sale_price'] != null
        ? (map['sale_price'] as num).toDouble()
        : null;

    // Resolve price and originalPrice from normalized columns
    final price = salePrice ?? basePrice;
    final originalPrice = salePrice != null ? basePrice : null;

    // Parse variants from joined product_variants(*) array
    final variantsList = (map['variants'] as List?)
            ?.map((v) => VariantModel.fromMap(v as Map<String, dynamic>))
            .toList() ??
        const <VariantModel>[];

    return ProductModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: price,
      originalPrice: originalPrice,
      images: List<String>.from(map['images'] ?? []),
      categoryId: map['category_id'],
      category: map['category'] != null
          ? CategoryModel.fromMap(map['category'] as Map<String, dynamic>)
          : null,
      rating: map['avg_rating']?.toDouble(),
      reviewCount: map['review_count'] ?? 0,
      isFeatured: map['is_featured'] ?? false,
      isActive: map['is_active'] ?? true,
      material: map['material'],
      elasticity: map['elasticity'],
      storeId: map['store_id'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      variants: variantsList,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        originalPrice,
        images,
        categoryId,
        category,
        rating,
        reviewCount,
        isFeatured,
        isActive,
        material,
        elasticity,
        storeId,
        createdAt,
        variants,
      ];
}
