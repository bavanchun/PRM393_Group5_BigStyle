enum OrderStatus {
  pending,
  confirmed,
  preparing,
  shipping,
  delivered,
  cancelled;

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Chờ xác nhận';
      case OrderStatus.confirmed:
        return 'Đã xác nhận';
      case OrderStatus.preparing:
        return 'Đang chuẩn bị';
      case OrderStatus.shipping:
        return 'Đang giao hàng';
      case OrderStatus.delivered:
        return 'Đã giao hàng';
      case OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }

  bool get isActive => this != OrderStatus.cancelled && this != OrderStatus.delivered;
}
