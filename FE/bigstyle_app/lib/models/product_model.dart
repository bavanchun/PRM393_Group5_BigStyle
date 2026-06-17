import 'package:equatable/equatable.dart';
import 'category_model.dart';

class ProductModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final List<String> images;
  final List<String> sizes;
  final String? categoryId;
  final CategoryModel? category;
  final int stock;
  final double? rating;
  final int reviewCount;
  final bool isFeatured;
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.images,
    required this.sizes,
    this.categoryId,
    this.category,
    this.stock = 0,
    this.rating,
    this.reviewCount = 0,
    this.isFeatured = false,
    required this.createdAt,
  });

  double get discountPercent {
    if (originalPrice == null || originalPrice! <= price) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
  }

  bool get hasDiscount => discountPercent > 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'original_price': originalPrice,
        'images': images,
        'sizes': sizes,
        'category_id': categoryId,
        'stock': stock,
        'rating': rating,
        'review_count': reviewCount,
        'is_featured': isFeatured,
        'created_at': createdAt.toIso8601String(),
      };

  factory ProductModel.fromMap(Map<String, dynamic> map) => ProductModel(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        price: (map['price'] ?? 0).toDouble(),
        originalPrice: map['original_price']?.toDouble(),
        images: List<String>.from(map['images'] ?? []),
        sizes: List<String>.from(map['sizes'] ?? []),
        categoryId: map['category_id'],
        category: map['category'] != null
            ? CategoryModel.fromMap(map['category'])
            : null,
        stock: map['stock'] ?? 0,
        rating: map['rating']?.toDouble(),
        reviewCount: map['review_count'] ?? 0,
        isFeatured: map['is_featured'] ?? false,
        createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        originalPrice,
        images,
        sizes,
        categoryId,
        category,
        stock,
        rating,
        reviewCount,
        isFeatured,
        createdAt,
      ];
}
