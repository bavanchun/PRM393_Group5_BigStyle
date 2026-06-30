import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/product_service.dart';
import 'manager_product_event.dart';
import 'manager_product_state.dart';

class ManagerProductBloc extends Bloc<ManagerProductEvent, ManagerProductState> {
  final ProductService _productService;

  ManagerProductBloc(this._productService) : super(ManagerProductInitial()) {
    on<LoadManagerProductsEvent>(_onLoadProducts);
    on<CreateManagerProductEvent>(_onCreateProduct);
    on<UpdateManagerProductEvent>(_onUpdateProduct);
    on<DeleteManagerProductEvent>(_onDeleteProduct);
    on<UploadManagerProductImageEvent>(_onUploadImage);
  }

  Future<void> _onLoadProducts(
      LoadManagerProductsEvent event, Emitter<ManagerProductState> emit) async {
    emit(ManagerProductLoading());
    try {
      final products = await _productService.getProducts();
      emit(ManagerProductLoaded(products));
    } catch (e) {
      emit(ManagerProductError(e.toString()));
    }
  }

  Future<void> _onCreateProduct(
      CreateManagerProductEvent event, Emitter<ManagerProductState> emit) async {
    try {
      final newProduct = await _productService.createProductWithVariants(event.product);
      if (newProduct != null) {
        emit(const ManagerProductOperationSuccess('Tạo sản phẩm thành công!'));
        add(LoadManagerProductsEvent()); // Reload list
      } else {
        emit(const ManagerProductError('Lỗi khi tạo sản phẩm'));
      }
    } catch (e) {
      emit(ManagerProductError(e.toString()));
    }
  }

  Future<void> _onUpdateProduct(
      UpdateManagerProductEvent event, Emitter<ManagerProductState> emit) async {
    try {
      final updatedProduct = await _productService.updateProduct(event.product);
      if (updatedProduct != null) {
        emit(const ManagerProductOperationSuccess('Cập nhật sản phẩm thành công!'));
        add(LoadManagerProductsEvent());
      } else {
        emit(const ManagerProductError('Lỗi khi cập nhật sản phẩm'));
      }
    } catch (e) {
      emit(ManagerProductError(e.toString()));
    }
  }

  Future<void> _onDeleteProduct(
      DeleteManagerProductEvent event, Emitter<ManagerProductState> emit) async {
    try {
      await _productService.deleteProduct(event.id);
      emit(const ManagerProductOperationSuccess('Đã xóa sản phẩm thành công!'));
      add(LoadManagerProductsEvent());
    } catch (e) {
      emit(ManagerProductError(e.toString()));
    }
  }

  Future<void> _onUploadImage(
      UploadManagerProductImageEvent event, Emitter<ManagerProductState> emit) async {
    try {
      final url = await _productService.uploadProductImage(
          event.fileName, event.fileBytes, event.mimeType);
      if (url != null) {
        emit(ManagerProductImageUploaded(url));
      } else {
        emit(const ManagerProductError('Lỗi tải ảnh lên server'));
      }
    } catch (e) {
      emit(ManagerProductError(e.toString()));
    }
  }
}
