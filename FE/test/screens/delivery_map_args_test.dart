import 'package:bigstyle_app/models/order_status.dart';
import 'package:bigstyle_app/screens/delivery/delivery_map_args.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeliveryMapArgs.fromRouteArguments', () {
    test('parses destination + label + title from a coord-bearing map', () {
      final args = DeliveryMapArgs.fromRouteArguments({
        'latitude': 10.5,
        'longitude': 106.7,
        'label': '23 Test Street',
        'title': 'Lộ trình giao hàng',
      });

      expect(args, isNotNull);
      expect(args!.destination.latitude, 10.5);
      expect(args.destination.longitude, 106.7);
      expect(args.destinationLabel, '23 Test Street');
      expect(args.title, 'Lộ trình giao hàng');
    });

    test('returns null when coordinates are missing (store-locator mode)', () {
      expect(DeliveryMapArgs.fromRouteArguments({'label': 'x'}), isNull);
      expect(DeliveryMapArgs.fromRouteArguments(null), isNull);
      expect(DeliveryMapArgs.fromRouteArguments({'latitude': 10.5}), isNull);
    });
  });

  group('deliveryRouteCtaVisible', () {
    test('visible only for shipping orders with coordinates', () {
      expect(deliveryRouteCtaVisible(OrderStatus.shipping, 10.5, 106.7), isTrue);
    });

    test('hidden without coordinates', () {
      expect(deliveryRouteCtaVisible(OrderStatus.shipping, null, 106.7), isFalse);
      expect(deliveryRouteCtaVisible(OrderStatus.shipping, 10.5, null), isFalse);
    });

    test('hidden for non-shipping statuses even with coordinates', () {
      for (final status in [
        OrderStatus.pending,
        OrderStatus.confirmed,
        OrderStatus.delivered,
        OrderStatus.cancelled,
      ]) {
        expect(deliveryRouteCtaVisible(status, 10.5, 106.7), isFalse);
      }
    });
  });
}
