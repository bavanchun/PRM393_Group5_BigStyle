import 'package:bigstyle_app/models/order_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderStatus.isCancellable (customer cancel gate)', () {
    test('pending and confirmed are cancellable', () {
      expect(OrderStatus.pending.isCancellable, isTrue);
      expect(OrderStatus.confirmed.isCancellable, isTrue);
    });

    test(
      'shipping, delivered, cancelled, processing, refunded are not cancellable',
      () {
        expect(OrderStatus.shipping.isCancellable, isFalse);
        expect(OrderStatus.delivered.isCancellable, isFalse);
        expect(OrderStatus.cancelled.isCancellable, isFalse);
        expect(OrderStatus.processing.isCancellable, isFalse);
        expect(OrderStatus.refunded.isCancellable, isFalse);
      },
    );

    test('processing and refunded offer no manager next-status actions', () {
      expect(OrderStatus.processing.nextStatuses, isEmpty);
      expect(OrderStatus.refunded.nextStatuses, isEmpty);
    });

    test('refunded is not active; processing is', () {
      expect(OrderStatus.refunded.isActive, isFalse);
      expect(OrderStatus.processing.isActive, isTrue);
    });

    test('matches the state machine: cancellable iff nextStatuses has cancelled',
        () {
      for (final status in OrderStatus.values) {
        expect(
          status.isCancellable,
          status.nextStatuses.contains(OrderStatus.cancelled),
        );
      }
    });
  });
}
