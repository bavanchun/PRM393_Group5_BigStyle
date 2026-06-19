import 'package:equatable/equatable.dart';

abstract class ProductDetailEvent extends Equatable {
  const ProductDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadProductDetail extends ProductDetailEvent {
  final String productId;
  const LoadProductDetail(this.productId);

  @override
  List<Object?> get props => [productId];
}

class SelectColor extends ProductDetailEvent {
  final String color;
  const SelectColor(this.color);

  @override
  List<Object?> get props => [color];
}

class SelectSize extends ProductDetailEvent {
  final String size;
  const SelectSize(this.size);

  @override
  List<Object?> get props => [size];
}

class SetCurrentImageIndex extends ProductDetailEvent {
  final int index;
  const SetCurrentImageIndex(this.index);

  @override
  List<Object?> get props => [index];
}
