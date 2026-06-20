import 'package:flutter_bloc/flutter_bloc.dart';
import 'cart_event.dart';
import 'cart_state.dart';
import '../../services/cart_service.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartService _cartService;

  CartBloc(this._cartService) : super(const CartState()) {
    on<CartLoad>(_onLoad);
    on<CartAddItem>(_onAddItem);
    on<CartUpdateQuantity>(_onUpdateQuantity);
    on<CartRemoveItem>(_onRemoveItem);
    on<CartClear>(_onClear);
  }

  Future<void> _onLoad(CartLoad event, Emitter<CartState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final items = await _cartService.getCartItems(event.userId);
      emit(state.copyWith(isLoading: false, items: items));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Tải giỏ hàng thất bại'));
    }
  }

  Future<void> _onAddItem(CartAddItem event, Emitter<CartState> emit) async {
    try {
      await _cartService.addToCart(event.userId, event.variantId, event.quantity);
      // Reload from DB to get accurate state (quantity merge, product join)
      final items = await _cartService.getCartItems(event.userId);
      emit(state.copyWith(items: items));
    } catch (e) {
      emit(state.copyWith(error: 'Thêm sản phẩm thất bại'));
    }
  }

  Future<void> _onUpdateQuantity(
      CartUpdateQuantity event, Emitter<CartState> emit) async {
    try {
      await _cartService.updateQuantity(event.cartId, event.quantity);
      final items = state.items.map((item) {
        if (item.id == event.cartId) {
          return item.copyWith(quantity: event.quantity);
        }
        return item;
      }).toList();
      emit(state.copyWith(items: items));
    } catch (e) {
      emit(state.copyWith(error: 'Cập nhật thất bại'));
    }
  }

  Future<void> _onRemoveItem(
      CartRemoveItem event, Emitter<CartState> emit) async {
    try {
      await _cartService.removeFromCart(event.cartId);
      final items =
          state.items.where((item) => item.id != event.cartId).toList();
      emit(state.copyWith(items: items));
    } catch (e) {
      emit(state.copyWith(error: 'Xóa sản phẩm thất bại'));
    }
  }

  Future<void> _onClear(CartClear event, Emitter<CartState> emit) async {
    try {
      await _cartService.clearCart(event.userId);
      emit(state.copyWith(items: []));
    } catch (e) {
      emit(state.copyWith(error: 'Xóa giỏ hàng thất bại'));
    }
  }
}
