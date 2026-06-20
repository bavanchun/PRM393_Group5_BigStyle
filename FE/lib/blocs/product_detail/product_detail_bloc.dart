import 'package:flutter_bloc/flutter_bloc.dart';
import 'product_detail_event.dart';
import 'product_detail_state.dart';
import '../../services/product_service.dart';

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  final ProductService _productService;

  ProductDetailBloc(this._productService) : super(const ProductDetailState()) {
    on<LoadProductDetail>(_onLoadDetail);
    on<SelectColor>(_onSelectColor);
    on<SelectSize>(_onSelectSize);
    on<SetCurrentImageIndex>(_onSetImageIndex);
  }

  Future<void> _onLoadDetail(
    LoadProductDetail event,
    Emitter<ProductDetailState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final product = await _productService.getProductById(event.productId);
      if (product != null) {
        emit(
          state.copyWith(
            isLoading: false,
            product: product,
            selectedSize: product.sizes.isNotEmpty ? product.sizes.first : null,
          ),
        );
      } else {
        emit(
          state.copyWith(isLoading: false, error: 'Không tìm thấy sản phẩm'),
        );
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Tải chi tiết thất bại'));
    }
  }

  void _onSelectColor(SelectColor event, Emitter<ProductDetailState> emit) {
    emit(state.copyWith(selectedColor: event.color));
  }

  void _onSelectSize(SelectSize event, Emitter<ProductDetailState> emit) {
    emit(state.copyWith(selectedSize: event.size));
  }

  void _onSetImageIndex(
    SetCurrentImageIndex event,
    Emitter<ProductDetailState> emit,
  ) {
    emit(state.copyWith(currentImageIndex: event.index));
  }
}
