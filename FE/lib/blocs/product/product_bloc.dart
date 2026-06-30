import 'package:flutter_bloc/flutter_bloc.dart';
import 'product_event.dart';
import 'product_state.dart';
import '../../services/product_service.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductService _productService;

  ProductBloc(this._productService) : super(const ProductState()) {
    on<LoadProducts>(_onLoad);
    on<FilterByCategory>(_onFilterByCategory);
    on<SearchProducts>(_onSearch);
    on<SortProducts>(_onSort);
    on<ProductLoadFeatured>(_onLoadFeatured);
    on<ProductLoadDetail>(_onLoadDetail);
    on<ProductLoadCategories>(_onLoadCategories);
  }

  Future<void> _onLoad(LoadProducts event, Emitter<ProductState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final products = await _productService.getProducts();
      emit(state.copyWith(isLoading: false, products: products));
    } catch (e, stackTrace) {
      print('LoadProducts error: $e\n$stackTrace');
      emit(state.copyWith(isLoading: false, error: 'Tải sản phẩm thất bại'));
    }
  }

  void _onFilterByCategory(
      FilterByCategory event, Emitter<ProductState> emit) {
    emit(state.copyWith(selectedCategory: event.categoryId));
  }

  void _onSearch(SearchProducts event, Emitter<ProductState> emit) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onSort(SortProducts event, Emitter<ProductState> emit) {
    emit(state.copyWith(sortBy: event.sortBy));
  }

  Future<void> _onLoadFeatured(
      ProductLoadFeatured event, Emitter<ProductState> emit) async {
    try {
      final products = await _productService.getProducts(featured: true);
      emit(state.copyWith(featuredProducts: products));
    } catch (e, stackTrace) {
      print('ProductLoadFeatured error: $e\n$stackTrace');
    }
  }

  Future<void> _onLoadDetail(
      ProductLoadDetail event, Emitter<ProductState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final product = await _productService.getProductById(event.productId);
      emit(state.copyWith(isLoading: false, selectedProduct: product));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Tải chi tiết thất bại'));
    }
  }

  Future<void> _onLoadCategories(
      ProductLoadCategories event, Emitter<ProductState> emit) async {
    try {
      final categories = await _productService.getCategories();
      emit(state.copyWith(categories: categories));
    } catch (_) {}
  }
}
