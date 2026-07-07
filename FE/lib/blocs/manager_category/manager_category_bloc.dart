import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/category_service.dart';
import '../../services/product_service.dart';
import 'manager_category_event.dart';
import 'manager_category_state.dart';

class ManagerCategoryBloc
    extends Bloc<ManagerCategoryEvent, ManagerCategoryState> {
  final CategoryService _categoryService;
  // Image upload reuses the products storage bucket helper on ProductService.
  final ProductService _productService;

  ManagerCategoryBloc(this._categoryService, this._productService)
      : super(ManagerCategoryInitial()) {
    on<LoadManagerCategoriesEvent>(_onLoad);
    on<CreateManagerCategoryEvent>(_onCreate);
    on<UpdateManagerCategoryEvent>(_onUpdate);
    on<SoftDeleteManagerCategoryEvent>(_onSoftDelete);
    on<UploadManagerCategoryImageEvent>(_onUploadImage);
  }

  Future<void> _onLoad(
      LoadManagerCategoriesEvent event, Emitter<ManagerCategoryState> emit) async {
    emit(ManagerCategoryLoading());
    try {
      final categories = await _categoryService.getCategoriesForManager();
      emit(ManagerCategoryLoaded(categories));
    } catch (e) {
      emit(ManagerCategoryError(e.toString()));
    }
  }

  Future<void> _onCreate(
      CreateManagerCategoryEvent event, Emitter<ManagerCategoryState> emit) async {
    try {
      final created = await _categoryService.createCategory(event.category);
      if (created != null) {
        emit(const ManagerCategoryOperationSuccess('Tạo danh mục thành công!'));
        add(LoadManagerCategoriesEvent());
      } else {
        emit(const ManagerCategoryError('Lỗi khi tạo danh mục'));
      }
    } catch (e) {
      emit(ManagerCategoryError(e.toString()));
    }
  }

  Future<void> _onUpdate(
      UpdateManagerCategoryEvent event, Emitter<ManagerCategoryState> emit) async {
    try {
      final updated = await _categoryService.updateCategory(
        event.category,
        previousName: event.previousName,
      );
      if (updated != null) {
        emit(const ManagerCategoryOperationSuccess('Cập nhật danh mục thành công!'));
        add(LoadManagerCategoriesEvent());
      } else {
        emit(const ManagerCategoryError('Lỗi khi cập nhật danh mục'));
      }
    } catch (e) {
      emit(ManagerCategoryError(e.toString()));
    }
  }

  Future<void> _onSoftDelete(SoftDeleteManagerCategoryEvent event,
      Emitter<ManagerCategoryState> emit) async {
    try {
      await _categoryService.softDeleteCategory(event.id);
      emit(const ManagerCategoryOperationSuccess('Đã ẩn danh mục thành công!'));
      add(LoadManagerCategoriesEvent());
    } catch (e) {
      emit(ManagerCategoryError(e.toString()));
    }
  }

  Future<void> _onUploadImage(UploadManagerCategoryImageEvent event,
      Emitter<ManagerCategoryState> emit) async {
    try {
      final url = await _productService.uploadProductImage(
          event.fileName, event.fileBytes, event.mimeType);
      if (url != null) {
        emit(ManagerCategoryImageUploaded(url));
      } else {
        emit(const ManagerCategoryError('Lỗi tải ảnh lên server'));
      }
    } catch (e) {
      emit(ManagerCategoryError(e.toString()));
    }
  }
}
