class RevenueRecognition {
  static const acceptedStatuses = {'confirmed', 'shipping', 'delivered'};

  static double recognizedRevenue(Iterable<Map<String, dynamic>> orders) {
    return orders
        .where(isRecognizedOrder)
        .fold<double>(0, (total, order) => total + orderTotal(order));
  }

  static double recognizedRevenueForLocalDate(
    Iterable<Map<String, dynamic>> orders,
    DateTime localDate,
  ) {
    final targetDate = localDate.toLocal();
    return orders
        .where((order) {
          final createdAt = orderCreatedAt(order);
          return isRecognizedOrder(order) &&
              createdAt != null &&
              createdAt.year == targetDate.year &&
              createdAt.month == targetDate.month &&
              createdAt.day == targetDate.day;
        })
        .fold<double>(0, (total, order) => total + orderTotal(order));
  }

  static bool isRecognizedOrder(Map<String, dynamic> order) {
    return acceptedStatuses.contains(order['status']);
  }

  static double orderTotal(Map<String, dynamic> order) {
    return (order['total'] as num?)?.toDouble() ?? 0;
  }

  static DateTime? orderCreatedAt(Map<String, dynamic> order) {
    final raw = order['created_at'];
    if (raw is DateTime) return raw.toLocal();
    return DateTime.tryParse(raw as String? ?? '')?.toLocal();
  }
}
