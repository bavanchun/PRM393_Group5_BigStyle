import 'package:flutter_bloc/flutter_bloc.dart';
import 'order_event.dart';
import 'order_state.dart';
import '../../services/order_service.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderService _orderService;

  OrderBloc(this._orderService) : super(const OrderState()) {
    on<OrderLoad>(_onLoad);
    on<OrderLoadDetail>(_onLoadDetail);
  }

  Future<void> _onLoad(OrderLoad event, Emitter<OrderState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final orders = await _orderService.getOrders(event.userId);
      emit(state.copyWith(isLoading: false, orders: orders));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Tải đơn hàng thất bại'));
    }
  }

  Future<void> _onLoadDetail(
      OrderLoadDetail event, Emitter<OrderState> emit) async {
    // Clear any previously selected order so a new/failed detail load never
    // renders the stale order from a prior view (the error/not-found UI in
    // order_detail_screen keys off selectedOrder == null).
    emit(state.copyWith(isLoading: true, clearSelectedOrder: true));
    try {
      final order = await _orderService.getOrderById(event.orderId);
      emit(state.copyWith(isLoading: false, selectedOrder: order));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Tải chi tiết thất bại',
        clearSelectedOrder: true,
      ));
    }
  }
}
