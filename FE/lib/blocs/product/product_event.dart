import 'package:equatable/equatable.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductEvent {
  const LoadProducts();
}

class FilterByCategory extends ProductEvent {
  final String? categoryId;
  final String label;
  const FilterByCategory(this.categoryId, this.label);

  @override
  List<Object?> get props => [categoryId, label];
}

class SearchProducts extends ProductEvent {
  final String query;
  const SearchProducts(this.query);

  @override
  List<Object?> get props => [query];
}

class SortProducts extends ProductEvent {
  final String sortBy;
  const SortProducts(this.sortBy);

  @override
  List<Object?> get props => [sortBy];
}

class ProductLoadFeatured extends ProductEvent {
  const ProductLoadFeatured();
}

class ProductLoadDetail extends ProductEvent {
  final String productId;
  const ProductLoadDetail(this.productId);

  @override
  List<Object?> get props => [productId];
}

class ProductLoadCategories extends ProductEvent {
  const ProductLoadCategories();
}
