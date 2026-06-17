import 'package:equatable/equatable.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class ProductLoad extends ProductEvent {
  final String? categoryId;
  final String? searchQuery;
  const ProductLoad({this.categoryId, this.searchQuery});

  @override
  List<Object?> get props => [categoryId, searchQuery];
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
