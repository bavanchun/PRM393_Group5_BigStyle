import 'package:equatable/equatable.dart';
import '../../models/product_model.dart';

abstract class ManagerProductState extends Equatable {
  const ManagerProductState();

  @override
  List<Object?> get props => [];
}

class ManagerProductInitial extends ManagerProductState {}

class ManagerProductLoading extends ManagerProductState {}

class ManagerProductLoaded extends ManagerProductState {
  final List<ProductModel> products;

  const ManagerProductLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

class ManagerProductOperationSuccess extends ManagerProductState {
  final String message;

  const ManagerProductOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ManagerProductError extends ManagerProductState {
  final String error;

  const ManagerProductError(this.error);

  @override
  List<Object?> get props => [error];
}

class ManagerProductImageUploaded extends ManagerProductState {
  final String imageUrl;

  const ManagerProductImageUploaded(this.imageUrl);

  @override
  List<Object?> get props => [imageUrl];
}
