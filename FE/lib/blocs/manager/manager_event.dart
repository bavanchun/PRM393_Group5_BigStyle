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
  final DateTime? fromDate;
  final DateTime? toDate;

  const ManagerLoadOrders({this.status, this.fromDate, this.toDate});

  @override
  List<Object?> get props => [status, fromDate, toDate];
}

/// Manager updates an order's status. Bloc calls OrderService.updateOrderStatus
/// then reloads the list keeping the current selectedStatus filter.
/// A DB trigger auto-creates the customer notification — no FE code needed.
class ManagerUpdateOrderStatus extends ManagerEvent {
  final String orderId;
  final OrderStatus status;
  final String? reason;

  const ManagerUpdateOrderStatus({
    required this.orderId,
    required this.status,
    this.reason,
  });

  @override
  List<Object?> get props => [orderId, status, reason];
}
