import 'package:equatable/equatable.dart';
import '../../models/order_status.dart';

sealed class ManagerEvent extends Equatable {
  const ManagerEvent();

  @override
  List<Object?> get props => [];
}

class ManagerLoadDashboard extends ManagerEvent {
  const ManagerLoadDashboard();
}

class ManagerLoadOrders extends ManagerEvent {
  final String? status;

  const ManagerLoadOrders({this.status});

  @override
  List<Object?> get props => [status];
}

/// Manager updates an order's status. Bloc calls OrderService.updateOrderStatus
/// then reloads the list keeping the current selectedStatus filter.
/// A DB trigger auto-creates the customer notification — no FE code needed.
class ManagerUpdateOrderStatus extends ManagerEvent {
  final String orderId;
  final OrderStatus status;

  const ManagerUpdateOrderStatus({required this.orderId, required this.status});

  @override
  List<Object?> get props => [orderId, status];
}
