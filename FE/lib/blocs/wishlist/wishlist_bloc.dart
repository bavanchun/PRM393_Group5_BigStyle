import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/wishlist_service.dart';
import 'wishlist_event.dart';
import 'wishlist_state.dart';

class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  final WishlistService _wishlistService;

  WishlistBloc(this._wishlistService) : super(const WishlistState()) {
    on<WishlistLoad>(_onLoad);
    on<WishlistToggle>(_onToggle);
  }

  Future<void> _onLoad(WishlistLoad event, Emitter<WishlistState> emit) async {
    final userId = event.userId;
    if (userId == null || userId.isEmpty || userId.startsWith('mock-')) {
      emit(const WishlistState());
      return;
    }
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final products = await _wishlistService.getWishlist(userId);
      emit(
        state.copyWith(
          isLoading: false,
          products: products,
          productIds: products.map((p) => p.id).toSet(),
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoading: false, error: 'Tải danh sách yêu thích thất bại'));
    }
  }

  Future<void> _onToggle(
    WishlistToggle event,
    Emitter<WishlistState> emit,
  ) async {
    final wasWishlisted = state.productIds.contains(event.productId);
    final previousIds = state.productIds;
    final previousProducts = state.products;

    // Optimistic update so the heart flips instantly.
    final nextIds = Set<String>.from(previousIds);
    if (wasWishlisted) {
      nextIds.remove(event.productId);
    } else {
      nextIds.add(event.productId);
    }
    final nextProducts = wasWishlisted
        ? previousProducts.where((p) => p.id != event.productId).toList()
        : previousProducts;
    emit(state.copyWith(productIds: nextIds, products: nextProducts, clearError: true));

    try {
      if (wasWishlisted) {
        await _wishlistService.remove(event.userId, event.productId);
      } else {
        await _wishlistService.add(event.userId, event.productId);
        // Refetch so the newly added product (with full data) appears in the grid.
        final products = await _wishlistService.getWishlist(event.userId);
        emit(
          state.copyWith(
            products: products,
            productIds: products.map((p) => p.id).toSet(),
          ),
        );
      }
    } catch (_) {
      // Roll back to the pre-toggle snapshot on failure.
      emit(
        state.copyWith(
          productIds: previousIds,
          products: previousProducts,
          error: 'Cập nhật yêu thích thất bại',
        ),
      );
    }
  }
}
