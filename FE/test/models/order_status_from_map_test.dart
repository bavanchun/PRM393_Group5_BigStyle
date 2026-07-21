import 'package:bigstyle_app/models/order_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderModel.fromMap status resolution', () {
    test('maps all 7 DB order_status enum values explicitly', () {
      const dbValues = [
        'pending',
        'confirmed',
        'processing',
        'shipping',
        'delivered',
        'cancelled',
        'refunded',
      ];

      for (final value in dbValues) {
        final order = OrderModel.fromMap({'id': 'o1', 'status': value});
        expect(
          order.status.name,
          value,
          reason: '"$value" must resolve to OrderStatus.$value, not fall back',
        );
      }
    });

    test(
      'unrecognized status trips the debug-mode visibility assert '
      '(RT-13: unknowns must be loud, not silently mapped to pending)',
      () {
        expect(
          () => OrderModel.fromMap({'id': 'o1', 'status': 'not_a_status'}),
          throwsA(isA<AssertionError>()),
        );
      },
    );
  });
}
