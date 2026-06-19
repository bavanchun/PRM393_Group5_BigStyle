import 'package:equatable/equatable.dart';
import '../../models/product_model.dart';

class ProductReview {
  final String name;
  final double rating;
  final String date;
  final String comment;
  final String? avatarUrl;

  const ProductReview({
    required this.name,
    required this.rating,
    required this.date,
    required this.comment,
    this.avatarUrl,
  });
}

class ProductDetailState extends Equatable {
  final bool isLoading;
  final ProductModel? product;
  final String? error;
  final String selectedColor;
  final String? selectedSize;
  final int currentImageIndex;
  final List<String> availableColors;
  final List<ProductReview> reviews;

  const ProductDetailState({
    this.isLoading = false,
    this.product,
    this.error,
    this.selectedColor = '',
    this.selectedSize,
    this.currentImageIndex = 0,
    this.availableColors = const [],
    this.reviews = const [],
  });

  String get displayPrice {
    if (product == null) return '';
    return '${product!.price.toStringAsFixed(0)}đ';
  }

  String get displayOriginalPrice {
    if (product == null || !product!.hasDiscount) return '';
    return '${product!.originalPrice!.toStringAsFixed(0)}đ';
  }

  ProductDetailState copyWith({
    bool? isLoading,
    ProductModel? product,
    String? error,
    String? selectedColor,
    String? selectedSize,
    int? currentImageIndex,
    List<String>? availableColors,
    List<ProductReview>? reviews,
  }) =>
      ProductDetailState(
        isLoading: isLoading ?? this.isLoading,
        product: product ?? this.product,
        error: error,
        selectedColor: selectedColor ?? this.selectedColor,
        selectedSize: selectedSize ?? this.selectedSize,
        currentImageIndex: currentImageIndex ?? this.currentImageIndex,
        availableColors: availableColors ?? this.availableColors,
        reviews: reviews ?? this.reviews,
      );

  @override
  List<Object?> get props => [
        isLoading,
        product,
        error,
        selectedColor,
        selectedSize,
        currentImageIndex,
        availableColors,
        reviews,
      ];
}
