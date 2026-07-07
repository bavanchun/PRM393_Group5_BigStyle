import 'package:equatable/equatable.dart';
import '../../models/category_model.dart';

abstract class ManagerCategoryState extends Equatable {
  const ManagerCategoryState();

  @override
  List<Object?> get props => [];
}

class ManagerCategoryInitial extends ManagerCategoryState {}

class ManagerCategoryLoading extends ManagerCategoryState {}

class ManagerCategoryLoaded extends ManagerCategoryState {
  final List<CategoryModel> categories;

  const ManagerCategoryLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class ManagerCategoryOperationSuccess extends ManagerCategoryState {
  final String message;

  const ManagerCategoryOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ManagerCategoryError extends ManagerCategoryState {
  final String error;

  const ManagerCategoryError(this.error);

  @override
  List<Object?> get props => [error];
}

class ManagerCategoryImageUploaded extends ManagerCategoryState {
  final String imageUrl;

  const ManagerCategoryImageUploaded(this.imageUrl);

  @override
  List<Object?> get props => [imageUrl];
}
