import 'package:bigstyle_app/models/manager_dashboard_stats.dart';
import 'package:bigstyle_app/models/revenue_recognition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RevenueRecognition', () {
    test('admin all-time revenue includes only recognized statuses', () {
      final orders = [
        {'status': 'confirmed', 'total': 100},
        {'status': 'shipping', 'total': 200},
        {'status': 'delivered', 'total': 300},
        {'status': 'pending', 'total': 400},
        {'status': 'cancelled', 'total': 500},
        {'status': 'refunded', 'total': 600},
        {'status': 'confirmed', 'total': null},
      ];

      expect(RevenueRecognition.recognizedRevenue(orders), 600);
    });

    test(
      'manager today revenue ignores other dates and unrecognized statuses',
      () {
        final now = DateTime(2026, 7, 10, 12);
        final orders = [
          {
            'status': 'confirmed',
            'total': 100,
            'created_at': '2026-07-10T01:00:00',
          },
          {
            'status': 'shipping',
            'total': 200,
            'created_at': '2026-07-10T12:00:00',
          },
          {
            'status': 'delivered',
            'total': 250,
            'created_at': '2026-07-10T18:00:00',
          },
          {
            'status': 'delivered',
            'total': 300,
            'created_at': '2026-07-09T23:59:00',
          },
          {
            'status': 'pending',
            'total': 400,
            'created_at': '2026-07-10T10:00:00',
          },
          {
            'status': 'refunded',
            'total': 500,
            'created_at': '2026-07-10T10:00:00',
          },
          {
            'status': 'cancelled',
            'total': 500,
            'created_at': '2026-07-10T10:00:00',
          },
          {
            'status': 'unknown',
            'total': 500,
            'created_at': '2026-07-10T10:00:00',
          },
        ];

        final stats = ManagerDashboardStats.fromRows(
          orders: orders,
          products: const [],
          customerCount: 0,
          now: now,
        );

        expect(
          RevenueRecognition.recognizedRevenueForLocalDate(orders, now),
          550,
        );
        expect(stats.todayRevenue, 550);
      },
    );

    test(
      'manager today revenue handles UTC timestamps at local-day boundary',
      () {
        final vietnamMidday = DateTime(2026, 7, 10, 12);
        final orders = [
          {
            'status': 'confirmed',
            'total': 100,
            'created_at': '2026-07-09T17:30:00Z',
          },
          {
            'status': 'delivered',
            'total': 200,
            'created_at': '2026-07-10T16:59:59Z',
          },
          {
            'status': 'shipping',
            'total': 300,
            'created_at': '2026-07-10T17:00:00Z',
          },
        ];

        expect(
          RevenueRecognition.recognizedRevenueForLocalDate(
            orders,
            vietnamMidday,
          ),
          300,
        );
      },
    );
  });
}
