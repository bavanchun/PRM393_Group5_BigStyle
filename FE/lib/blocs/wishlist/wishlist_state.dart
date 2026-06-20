import 'package:equatable/equatable.dart';
import '../../models/product_model.dart';

class WishlistState extends Equatable {
  final bool isLoading;
  // Source of truth for heart state across all cards — O(1) membership check.
  final Set<String> productIds;
  // Full products for the Favorites grid (kept in sync with productIds).
  final List<ProductModel> products;
  final String? error;

  const WishlistState({
    this.isLoading = false,
    this.productIds = const {},
    this.products = const [],
    this.error,
  });

  bool contains(String productId) => productIds.contains(productId);

  WishlistState copyWith({
    bool? isLoading,
    Set<String>? productIds,
    List<ProductModel>? products,
    String? error,
    bool clearError = false,
  }) {
    return WishlistState(
      isLoading: isLoading ?? this.isLoading,
      productIds: productIds ?? this.productIds,
      products: products ?? this.products,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [isLoading, productIds, products, error];
}
