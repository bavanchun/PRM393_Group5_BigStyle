import 'package:equatable/equatable.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';

class ProductState extends Equatable {
  final bool isLoading;
  final List<ProductModel> products;
  final List<ProductModel> featuredProducts;
  final List<CategoryModel> categories;
  final ProductModel? selectedProduct;
  final String? selectedCategory;
  final String searchQuery;
  final String sortBy;
  final String? error;

  const ProductState({
    this.isLoading = false,
    this.products = const [],
    this.featuredProducts = const [],
    this.categories = const [],
    this.selectedProduct,
    this.selectedCategory,
    this.searchQuery = '',
    this.sortBy = 'newest',
    this.error,
  });

  List<ProductModel> get filteredProducts {
    var result = products;

    if (selectedCategory != null && selectedCategory != 'all') {
      result = result.where((p) =>
          p.category?.name == selectedCategory ||
          p.categoryId == selectedCategory).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((p) =>
          p.name.toLowerCase().contains(q) ||
          (p.category?.name.toLowerCase().contains(q) ?? false)).toList();
    }

    switch (sortBy) {
      case 'price-asc':
        result.sort((a, b) => a.price.compareTo(b.price));
      case 'price-desc':
        result.sort((a, b) => b.price.compareTo(a.price));
      case 'name':
        result.sort((a, b) => a.name.compareTo(b.name));
      case 'newest':
      default:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return result;
  }

  ProductState copyWith({
    bool? isLoading,
    List<ProductModel>? products,
    List<ProductModel>? featuredProducts,
    List<CategoryModel>? categories,
    ProductModel? selectedProduct,
    String? selectedCategory,
    String? searchQuery,
    String? sortBy,
    String? error,
  }) =>
      ProductState(
        isLoading: isLoading ?? this.isLoading,
        products: products ?? this.products,
        featuredProducts: featuredProducts ?? this.featuredProducts,
        categories: categories ?? this.categories,
        selectedProduct: selectedProduct ?? this.selectedProduct,
        selectedCategory: selectedCategory ?? this.selectedCategory,
        searchQuery: searchQuery ?? this.searchQuery,
        sortBy: sortBy ?? this.sortBy,
        error: error,
      );

  @override
  List<Object?> get props => [
        isLoading,
        products,
        featuredProducts,
        categories,
        selectedProduct,
        selectedCategory,
        searchQuery,
        sortBy,
        error,
      ];
}
