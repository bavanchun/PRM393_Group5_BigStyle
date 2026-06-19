import 'package:flutter_bloc/flutter_bloc.dart';
import 'product_detail_event.dart';
import 'product_detail_state.dart';
import '../../services/product_service.dart';

class ProductDetailBloc
    extends Bloc<ProductDetailEvent, ProductDetailState> {
  final ProductService _productService;

  ProductDetailBloc(this._productService) : super(const ProductDetailState()) {
    on<LoadProductDetail>(_onLoadDetail);
    on<SelectColor>(_onSelectColor);
    on<SelectSize>(_onSelectSize);
    on<SetCurrentImageIndex>(_onSetImageIndex);
  }

  Future<void> _onLoadDetail(
      LoadProductDetail event, Emitter<ProductDetailState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final product = await _productService.getProductById(event.productId);
      if (product != null) {
        emit(state.copyWith(
          isLoading: false,
          product: product,
          selectedSize: product.sizes.isNotEmpty ? product.sizes.first : null,
          reviews: _mockReviews(),
        ));
      } else {
        emit(state.copyWith(
            isLoading: false, error: 'Không tìm thấy sản phẩm'));
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
      SetCurrentImageIndex event, Emitter<ProductDetailState> emit) {
    emit(state.copyWith(currentImageIndex: event.index));
  }

  List<ProductReview> _mockReviews() {
    return const [
      ProductReview(
        name: 'Nguyễn Thị Hương',
        rating: 5,
        date: '2 ngày trước',
        comment:
            'Chất vải rất đẹp, mặc lên người thoải mái. Mình mua size 2XL vừa vặn. Sẽ ủng hộ shop tiếp!',
      ),
      ProductReview(
        name: 'Trần Văn Minh',
        rating: 4,
        date: '5 ngày trước',
        comment:
            'Áo đẹp, màu sắc giống hình. Giao hàng nhanh. Chỉ hơi dài tay một chút.',
      ),
      ProductReview(
        name: 'Lê Thị Mai',
        rating: 5,
        date: '1 tuần trước',
        comment:
            'Lần đầu mua hàng bigsize ưng ý. Dáng áo che khuyết điểm tốt. Chất liệu dày dặn.',
      ),
    ];
  }
}
