import 'package:bigstyle_app/models/manager_dashboard_stats.dart';
import 'package:bigstyle_app/models/order_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ManagerDashboardStats', () {
    test('aggregates delivered revenue and real entity counts', () {
      final stats = ManagerDashboardStats.fromRows(
        now: DateTime(2026, 6, 20, 12),
        orders: [
          {
            'status': 'delivered',
            'total': 250000,
            'created_at': '2026-06-20T03:00:00Z',
          },
          {
            'status': 'pending',
            'total': 150000,
            'created_at': '2026-06-20T04:00:00Z',
          },
          {
            'status': 'delivered',
            'total': 500000,
            'created_at': '2026-06-19T03:00:00Z',
          },
        ],
        products: const [
          {'id': 'p1'},
          {'id': 'p2'},
        ],
        profiles: const [
          {'id': 'c1', 'role': 'customer'},
          {'id': 'm1', 'role': 'manager'},
        ],
      );

      expect(stats.todayRevenue, 250000);
      expect(stats.pendingOrderCount, 1);
      expect(stats.productCount, 2);
      expect(stats.customerCount, 1);
    });
  });

  group('OrderModel manager joins', () {
    test('reads customer name from joined profile', () {
      final order = OrderModel.fromMap({
        'id': 'order-1',
        'user_id': 'user-1',
        'customer': {'full_name': 'Nguyễn Văn A'},
        'shipping_address': {'name': 'Tên giao hàng'},
        'subtotal': 100000,
        'total': 100000,
        'status': 'pending',
        'created_at': '2026-06-20T00:00:00Z',
      });

      expect(order.customerName, 'Nguyễn Văn A');
    });

    test('falls back to shipping recipient name', () {
      final order = OrderModel.fromMap({
        'id': 'order-2',
        'user_id': 'user-2',
        'shipping_address': {'name': 'Trần Thị B'},
        'subtotal': 100000,
        'total': 100000,
        'status': 'pending',
        'created_at': '2026-06-20T00:00:00Z',
      });

      expect(order.customerName, 'Trần Thị B');
    });
  });
}
