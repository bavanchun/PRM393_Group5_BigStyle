enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipping,
  delivered,
  cancelled,
  refunded;

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Chờ xác nhận';
      case OrderStatus.confirmed:
        return 'Đã xác nhận';
      case OrderStatus.processing:
        return 'Đang xử lý';
      case OrderStatus.shipping:
        return 'Đang giao hàng';
      case OrderStatus.delivered:
        return 'Đã giao hàng';
      case OrderStatus.cancelled:
        return 'Đã hủy';
      case OrderStatus.refunded:
        return 'Đã hoàn tiền';
    }
  }

  bool get isActive =>
      this != OrderStatus.cancelled &&
      this != OrderStatus.delivered &&
      this != OrderStatus.refunded;

  /// Valid next statuses a manager can transition this order to.
  /// Terminal statuses (cancelled, refunded) have no further transitions.
  List<OrderStatus> get nextStatuses {
    switch (this) {
      case OrderStatus.pending:
        return const [OrderStatus.confirmed, OrderStatus.cancelled];
      case OrderStatus.confirmed:
        return const [OrderStatus.processing, OrderStatus.cancelled];
      case OrderStatus.processing:
        return const [OrderStatus.shipping, OrderStatus.cancelled];
      case OrderStatus.shipping:
        return const [OrderStatus.delivered];
      case OrderStatus.delivered:
        return const [OrderStatus.refunded];
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        return const [];
    }
  }
}
