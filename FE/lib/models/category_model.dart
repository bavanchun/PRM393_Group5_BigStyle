import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final String id;
  final String name;
  final String? imageUrl;
  final int productCount;

  const CategoryModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.productCount = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'image_url': imageUrl,
        'product_count': productCount,
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        imageUrl: map['image_url'],
        productCount: map['product_count'] ?? 0,
      );

  @override
  List<Object?> get props => [id, name, imageUrl, productCount];
}
