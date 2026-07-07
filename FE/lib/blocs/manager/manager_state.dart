import 'package:equatable/equatable.dart';
import '../../models/manager_dashboard_stats.dart';
import '../../models/order_model.dart';

class ManagerState extends Equatable {
  final bool isDashboardLoading;
  final bool isOrdersLoading;
  final bool isUpdatingStatus;
  final ManagerDashboardStats? dashboardStats;
  final List<OrderModel> recentOrders;
  final List<OrderModel> orders;
  final String? selectedStatus;
  final String? error;

  const ManagerState({
    this.isDashboardLoading = false,
    this.isOrdersLoading = false,
    this.isUpdatingStatus = false,
    this.dashboardStats,
    this.recentOrders = const [],
    this.orders = const [],
    this.selectedStatus,
    this.error,
  });

  ManagerState copyWith({
    bool? isDashboardLoading,
    bool? isOrdersLoading,
    bool? isUpdatingStatus,
    ManagerDashboardStats? dashboardStats,
    List<OrderModel>? recentOrders,
    List<OrderModel>? orders,
    String? selectedStatus,
    bool clearSelectedStatus = false,
    String? error,
    bool clearError = false,
  }) {
    return ManagerState(
      isDashboardLoading: isDashboardLoading ?? this.isDashboardLoading,
      isOrdersLoading: isOrdersLoading ?? this.isOrdersLoading,
      isUpdatingStatus: isUpdatingStatus ?? this.isUpdatingStatus,
      dashboardStats: dashboardStats ?? this.dashboardStats,
      recentOrders: recentOrders ?? this.recentOrders,
      orders: orders ?? this.orders,
      selectedStatus: clearSelectedStatus
          ? null
          : selectedStatus ?? this.selectedStatus,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    isDashboardLoading,
    isOrdersLoading,
    isUpdatingStatus,
    dashboardStats,
    recentOrders,
    orders,
    selectedStatus,
    error,
  ];
}
