import 'package:equatable/equatable.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';

class ProductState extends Equatable {
  final bool isLoading;
  final List<ProductModel> products;
  final List<ProductModel> featuredProducts;
  final List<CategoryModel> categories;
  // True when the last categories load failed (chips stay hidden, but the
  // failure is observable rather than silently swallowed).
  final bool categoriesFailed;
  final ProductModel? selectedProduct;
  final String? selectedCategory;
  final String searchQuery;
  final String sortBy;
  final String? error;
  final String? selectedSize;
  final bool saleOnly;

  const ProductState({
    this.isLoading = false,
    this.products = const [],
    this.featuredProducts = const [],
    this.categories = const [],
    this.categoriesFailed = false,
    this.selectedProduct,
    this.selectedCategory,
    this.searchQuery = '',
    this.sortBy = 'newest',
    this.error,
    this.selectedSize,
    this.saleOnly = false,
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

    if (selectedSize != null) {
      result = result.where((p) => p.sizes.contains(selectedSize)).toList();
    }

    if (saleOnly) {
      result = result.where((p) => p.hasDiscount).toList();
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
    bool? categoriesFailed,
    ProductModel? selectedProduct,
    String? selectedCategory,
    String? searchQuery,
    String? sortBy,
    String? error,
    String? selectedSize,
    bool? saleOnly,
    bool clearSize = false,
  }) =>
      ProductState(
        isLoading: isLoading ?? this.isLoading,
        products: products ?? this.products,
        featuredProducts: featuredProducts ?? this.featuredProducts,
        categories: categories ?? this.categories,
        categoriesFailed: categoriesFailed ?? this.categoriesFailed,
        selectedProduct: selectedProduct ?? this.selectedProduct,
        selectedCategory: selectedCategory ?? this.selectedCategory,
        searchQuery: searchQuery ?? this.searchQuery,
        sortBy: sortBy ?? this.sortBy,
        error: error,
        selectedSize: clearSize ? null : (selectedSize ?? this.selectedSize),
        saleOnly: saleOnly ?? this.saleOnly,
      );

  @override
  List<Object?> get props => [
        isLoading,
        products,
        featuredProducts,
        categories,
        categoriesFailed,
        selectedProduct,
        selectedCategory,
        searchQuery,
        sortBy,
        error,
        selectedSize,
        saleOnly,
      ];
}
