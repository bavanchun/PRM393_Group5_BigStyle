import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/order_service.dart';
import 'manager_event.dart';
import 'manager_state.dart';

class ManagerBloc extends Bloc<ManagerEvent, ManagerState> {
  final OrderService _orderService;
  int _dashboardRequestId = 0;
  int _ordersRequestId = 0;

  ManagerBloc(this._orderService) : super(const ManagerState()) {
    on<ManagerLoadDashboard>(_onLoadDashboard);
    on<ManagerLoadOrders>(_onLoadOrders);
    on<ManagerUpdateOrderStatus>(_onUpdateOrderStatus);
  }

  Future<void> _onLoadDashboard(
    ManagerLoadDashboard event,
    Emitter<ManagerState> emit,
  ) async {
    final requestId = ++_dashboardRequestId;
    emit(state.copyWith(isDashboardLoading: true, clearError: true));
    try {
      final statsFuture = _orderService.getDashboardStats();
      final ordersFuture = _orderService.getAllOrders();
      final stats = await statsFuture;
      final orders = await ordersFuture;
      if (requestId != _dashboardRequestId) return;
      emit(
        state.copyWith(
          isDashboardLoading: false,
          dashboardStats: stats,
          recentOrders: orders.take(5).toList(),
        ),
      );
    } catch (_) {
      if (requestId != _dashboardRequestId) return;
      emit(
        state.copyWith(
          isDashboardLoading: false,
          error: 'Tải tổng quan quản lý thất bại',
        ),
      );
    }
  }

  Future<void> _onLoadOrders(
    ManagerLoadOrders event,
    Emitter<ManagerState> emit,
  ) async {
    final requestId = ++_ordersRequestId;
    emit(
      state.copyWith(
        isOrdersLoading: true,
        selectedStatus: event.status,
        clearSelectedStatus: event.status == null,
        clearError: true,
      ),
    );
    try {
      final orders = await _orderService.getAllOrders(status: event.status);
      if (requestId != _ordersRequestId) return;
      emit(state.copyWith(isOrdersLoading: false, orders: orders));
    } catch (_) {
      if (requestId != _ordersRequestId) return;
      emit(
        state.copyWith(
          isOrdersLoading: false,
          error: 'Tải danh sách đơn hàng thất bại',
        ),
      );
    }
  }

  Future<void> _onUpdateOrderStatus(
    ManagerUpdateOrderStatus event,
    Emitter<ManagerState> emit,
  ) async {
    final requestId = ++_ordersRequestId;
    emit(state.copyWith(isUpdatingStatus: true, clearError: true));
    try {
      await _orderService.updateOrderStatus(
        event.orderId,
        event.status.name,
        reason: event.reason,
      );
      final orders = await _orderService.getAllOrders(
        status: state.selectedStatus,
      );
      if (requestId != _ordersRequestId) return;
      emit(
        state.copyWith(
          isUpdatingStatus: false,
          isOrdersLoading: false,
          orders: orders,
        ),
      );
    } catch (_) {
      if (requestId != _ordersRequestId) return;
      emit(
        state.copyWith(
          isUpdatingStatus: false,
          error: 'Cập nhật trạng thái đơn hàng thất bại',
        ),
      );
    }
  }
}
