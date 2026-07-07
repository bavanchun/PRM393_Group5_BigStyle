import 'package:equatable/equatable.dart';
import '../../models/category_model.dart';

abstract class ManagerCategoryEvent extends Equatable {
  const ManagerCategoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadManagerCategoriesEvent extends ManagerCategoryEvent {}

class CreateManagerCategoryEvent extends ManagerCategoryEvent {
  final CategoryModel category;

  const CreateManagerCategoryEvent(this.category);

  @override
  List<Object?> get props => [category];
}

class UpdateManagerCategoryEvent extends ManagerCategoryEvent {
  final CategoryModel category;
  final String previousName;

  const UpdateManagerCategoryEvent(this.category, this.previousName);

  @override
  List<Object?> get props => [category, previousName];
}

class SoftDeleteManagerCategoryEvent extends ManagerCategoryEvent {
  final String id;

  const SoftDeleteManagerCategoryEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class UploadManagerCategoryImageEvent extends ManagerCategoryEvent {
  final String fileName;
  final List<int> fileBytes;
  final String mimeType;

  const UploadManagerCategoryImageEvent({
    required this.fileName,
    required this.fileBytes,
    required this.mimeType,
  });

  @override
  List<Object?> get props => [fileName, fileBytes, mimeType];
}
