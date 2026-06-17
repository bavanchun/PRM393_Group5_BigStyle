import 'package:equatable/equatable.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';

class ProductState extends Equatable {
  final bool isLoading;
  final List<ProductModel> products;
  final List<ProductModel> featuredProducts;
  final List<CategoryModel> categories;
  final ProductModel? selectedProduct;
  final String? error;

  const ProductState({
    this.isLoading = false,
    this.products = const [],
    this.featuredProducts = const [],
    this.categories = const [],
    this.selectedProduct,
    this.error,
  });

  ProductState copyWith({
    bool? isLoading,
    List<ProductModel>? products,
    List<ProductModel>? featuredProducts,
    List<CategoryModel>? categories,
    ProductModel? selectedProduct,
    String? error,
  }) =>
      ProductState(
        isLoading: isLoading ?? this.isLoading,
        products: products ?? this.products,
        featuredProducts: featuredProducts ?? this.featuredProducts,
        categories: categories ?? this.categories,
        selectedProduct: selectedProduct ?? this.selectedProduct,
        error: error,
      );

  @override
  List<Object?> get props =>
      [isLoading, products, featuredProducts, categories, selectedProduct, error];
}
