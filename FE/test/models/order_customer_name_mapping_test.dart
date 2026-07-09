import 'package:bigstyle_app/models/order_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderModel.fromMap customerName resolution', () {
    test('resolves from shipping_address.name when no customer embed', () {
      final order = OrderModel.fromMap({
        'id': 'order-1',
        'user_id': 'user-1',
        'shipping_address': {
          'address': '23 Test Street',
          'name': 'Trần Thị Demo',
        },
        'subtotal': 100000,
        'total': 100000,
        'status': 'pending',
        'created_at': '2026-07-10T00:00:00Z',
      });

      expect(order.customerName, 'Trần Thị Demo');
    });

    test('returns null without throwing when name is absent everywhere', () {
      final order = OrderModel.fromMap({
        'id': 'order-2',
        'user_id': 'user-2',
        'shipping_address': {'address': '23 Test Street'},
        'subtotal': 100000,
        'total': 100000,
        'status': 'pending',
        'created_at': '2026-07-10T00:00:00Z',
      });

      expect(order.customerName, isNull);
    });

    test('still honors a customer embed when present (map-shape tolerance)', () {
      final order = OrderModel.fromMap({
        'id': 'order-3',
        'user_id': 'user-3',
        'customer': {'full_name': 'Embedded Name'},
        'shipping_address': {
          'address': '23 Test Street',
          'name': 'Shipping Name',
        },
        'subtotal': 100000,
        'total': 100000,
        'status': 'pending',
        'created_at': '2026-07-10T00:00:00Z',
      });

      expect(order.customerName, 'Embedded Name');
    });
  });
}
