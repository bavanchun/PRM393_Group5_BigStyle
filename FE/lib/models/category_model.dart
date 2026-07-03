import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final String id;
  final String name;
  final String? slug;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;
  final int productCount;

  const CategoryModel({
    required this.id,
    required this.name,
    this.slug,
    this.imageUrl,
    this.sortOrder = 0,
    this.isActive = true,
    this.productCount = 0,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? imageUrl,
    int? sortOrder,
    bool? isActive,
    int? productCount,
  }) => CategoryModel(
        id: id ?? this.id,
        name: name ?? this.name,
        slug: slug ?? this.slug,
        imageUrl: imageUrl ?? this.imageUrl,
        sortOrder: sortOrder ?? this.sortOrder,
        isActive: isActive ?? this.isActive,
        productCount: productCount ?? this.productCount,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'slug': slug,
        'image_url': imageUrl,
        'sort_order': sortOrder,
        'is_active': isActive,
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        slug: map['slug'],
        imageUrl: map['image_url'],
        sortOrder: map['sort_order'] ?? 0,
        isActive: map['is_active'] ?? true,
        productCount: map['product_count'] ?? 0,
      );

  @override
  List<Object?> get props =>
      [id, name, slug, imageUrl, sortOrder, isActive, productCount];
}
