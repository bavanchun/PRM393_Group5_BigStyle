import 'package:equatable/equatable.dart';
import 'revenue_recognition.dart';

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
    required int customerCount,
    DateTime? now,
  }) {
    final localNow = now ?? DateTime.now();
    final todayRevenue = RevenueRecognition.recognizedRevenueForLocalDate(
      orders,
      localNow,
    );

    return ManagerDashboardStats(
      todayRevenue: todayRevenue,
      pendingOrderCount: orders
          .where((order) => order['status'] == 'pending')
          .length,
      productCount: products.length,
      customerCount: customerCount,
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
