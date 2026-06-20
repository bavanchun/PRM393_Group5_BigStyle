import 'package:equatable/equatable.dart';

class ManagerDashboardStats extends Equatable {
  final double todayRevenue;
  final int pendingOrderCount;
  final int productCount;
  final int customerCount;

  const ManagerDashboardStats({
    required this.todayRevenue,
    required this.pendingOrderCount,
    required this.productCount,
    required this.customerCount,
  });

  factory ManagerDashboardStats.fromRows({
    required List<Map<String, dynamic>> orders,
    required List<Map<String, dynamic>> products,
    required List<Map<String, dynamic>> profiles,
    DateTime? now,
  }) {
    final localNow = now ?? DateTime.now();
    final todayRevenue = orders
        .where((order) {
          final createdAt = DateTime.tryParse(
            order['created_at'] as String? ?? '',
          )?.toLocal();
          return order['status'] == 'delivered' &&
              createdAt != null &&
              createdAt.year == localNow.year &&
              createdAt.month == localNow.month &&
              createdAt.day == localNow.day;
        })
        .fold<double>(
          0,
          (total, order) => total + ((order['total'] as num?)?.toDouble() ?? 0),
        );

    return ManagerDashboardStats(
      todayRevenue: todayRevenue,
      pendingOrderCount: orders
          .where((order) => order['status'] == 'pending')
          .length,
      productCount: products.length,
      customerCount: profiles
          .where((profile) => profile['role'] == 'customer')
          .length,
    );
  }

  @override
  List<Object?> get props => [
    todayRevenue,
    pendingOrderCount,
    productCount,
    customerCount,
  ];
}
