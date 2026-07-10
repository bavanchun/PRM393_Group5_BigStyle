import 'package:bigstyle_app/models/order_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderItem.fromMap id resolution', () {
    test('parses the order_items row id when present', () {
      final item = OrderItem.fromMap({
        'id': 'order-item-1',
        'variant_id': 'variant-1',
        'product_name': 'Áo thun',
        'size': 'M',
        'color': 'Đen',
        'quantity': 2,
        'unit_price': 199000,
      });

      expect(item.id, 'order-item-1');
    });

    test('leaves id null when the row omits it (pre-insert checkout item)', () {
      final item = OrderItem.fromMap({
        'variant_id': 'variant-2',
        'product_name': 'Quần jeans',
        'size': 'L',
        'color': 'Xanh',
        'quantity': 1,
        'unit_price': 350000,
      });

      expect(item.id, isNull);
    });
  });
}
