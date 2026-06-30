import 'package:equatable/equatable.dart';
import '../../models/product_model.dart';

abstract class ManagerProductEvent extends Equatable {
  const ManagerProductEvent();

  @override
  List<Object?> get props => [];
}

class LoadManagerProductsEvent extends ManagerProductEvent {}

class CreateManagerProductEvent extends ManagerProductEvent {
  final ProductModel product;

  const CreateManagerProductEvent(this.product);

  @override
  List<Object?> get props => [product];
}

class UpdateManagerProductEvent extends ManagerProductEvent {
  final ProductModel product;

  const UpdateManagerProductEvent(this.product);

  @override
  List<Object?> get props => [product];
}

class DeleteManagerProductEvent extends ManagerProductEvent {
  final String id;

  const DeleteManagerProductEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class UploadManagerProductImageEvent extends ManagerProductEvent {
  final String fileName;
  final List<int> fileBytes;
  final String mimeType;

  const UploadManagerProductImageEvent({
    required this.fileName,
    required this.fileBytes,
    required this.mimeType,
  });

  @override
  List<Object?> get props => [fileName, fileBytes, mimeType];
}
