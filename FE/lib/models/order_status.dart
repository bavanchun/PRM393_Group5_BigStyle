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
        return 'Đang giao';
      case OrderStatus.delivered:
        return 'Hoàn thành';
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

  /// A customer may cancel exactly when the state machine allows a transition
  /// to `cancelled` (pending or confirmed).
  bool get isCancellable => nextStatuses.contains(OrderStatus.cancelled);

  static const List<OrderStatus> happyPath = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.processing,
    OrderStatus.shipping,
    OrderStatus.delivered,
  ];

  /// Manager-actionable transitions. `processing`/`refunded` intentionally
  /// return none — those states arrive via webhook/admin/SQL, not this UI,
  /// so they render (see [label]) but offer no next-status buttons.
  List<OrderStatus> get nextStatuses {
    switch (this) {
      case OrderStatus.pending:
        return const [OrderStatus.confirmed, OrderStatus.cancelled];
      case OrderStatus.confirmed:
        return const [OrderStatus.shipping, OrderStatus.cancelled];
      case OrderStatus.processing:
        return const [];
      case OrderStatus.shipping:
        return const [OrderStatus.delivered];
      case OrderStatus.delivered:
        return const [];
      case OrderStatus.cancelled:
        return const [];
      case OrderStatus.refunded:
        return const [];
    }
  }
}
