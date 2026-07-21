import 'package:bigstyle_app/models/order_model.dart';
import 'package:bigstyle_app/models/order_status.dart';
import 'package:flutter_test/flutter_test.dart';

OrderModel _order({required OrderStatus status, DateTime? deliveredAt}) =>
    OrderModel(
      id: 'o1',
      userId: 'u1',
      items: const [],
      subtotal: 100000,
      total: 100000,
      status: status,
      createdAt: DateTime(2026, 7, 1),
      deliveredAt: deliveredAt,
    );

void main() {
  group('OrderModel.isRefundRequestWindowOpen', () {
    test('open just within the 7-day window', () {
      final order = _order(
        status: OrderStatus.delivered,
        deliveredAt: DateTime.now().subtract(const Duration(days: 6, hours: 23)),
      );
      expect(order.isRefundRequestWindowOpen, isTrue);
    });

    test('closed once 7 days have passed', () {
      final order = _order(
        status: OrderStatus.delivered,
        deliveredAt: DateTime.now().subtract(const Duration(days: 7, hours: 1)),
      );
      expect(order.isRefundRequestWindowOpen, isFalse);
    });

    test('closed when not delivered, even with a recent deliveredAt', () {
      final order = _order(
        status: OrderStatus.shipping,
        deliveredAt: DateTime.now(),
      );
      expect(order.isRefundRequestWindowOpen, isFalse);
    });

    test('closed when delivered but deliveredAt is null (legacy/unbackfilled row)',
        () {
      final order = _order(status: OrderStatus.delivered, deliveredAt: null);
      expect(order.isRefundRequestWindowOpen, isFalse);
    });
  });
}
