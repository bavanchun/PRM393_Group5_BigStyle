import 'package:equatable/equatable.dart';
import '../../models/order_model.dart';

class OrderState extends Equatable {
  final bool isLoading;
  final List<OrderModel> orders;
  final OrderModel? selectedOrder;
  final String? error;

  const OrderState({
    this.isLoading = false,
    this.orders = const [],
    this.selectedOrder,
    this.error,
  });

  OrderState copyWith({
    bool? isLoading,
    List<OrderModel>? orders,
    OrderModel? selectedOrder,
    bool clearSelectedOrder = false,
    String? error,
  }) =>
      OrderState(
        isLoading: isLoading ?? this.isLoading,
        orders: orders ?? this.orders,
        selectedOrder:
            clearSelectedOrder ? null : (selectedOrder ?? this.selectedOrder),
        error: error,
      );

  @override
  List<Object?> get props => [isLoading, orders, selectedOrder, error];
}
