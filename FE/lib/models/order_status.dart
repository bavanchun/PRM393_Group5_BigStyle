enum OrderStatus {
  pending,
  confirmed,
  shipping,
  delivered,
  cancelled;

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Chờ xác nhận';
      case OrderStatus.confirmed:
        return 'Đã xác nhận';
      case OrderStatus.shipping:
        return 'Đang giao';
      case OrderStatus.delivered:
        return 'Hoàn thành';
      case OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }

  bool get isActive =>
      this != OrderStatus.cancelled && this != OrderStatus.delivered;

  static const List<OrderStatus> happyPath = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.shipping,
    OrderStatus.delivered,
  ];

  List<OrderStatus> get nextStatuses {
    switch (this) {
      case OrderStatus.pending:
        return const [OrderStatus.confirmed, OrderStatus.cancelled];
      case OrderStatus.confirmed:
        return const [OrderStatus.shipping, OrderStatus.cancelled];
      case OrderStatus.shipping:
        return const [OrderStatus.delivered];
      case OrderStatus.delivered:
        return const [];
      case OrderStatus.cancelled:
        return const [];
    }
  }
}
