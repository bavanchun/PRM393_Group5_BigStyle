import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/order_status.dart';

/// Arguments passed to [DeliveryMapScreen] to switch it from store-locator mode
/// into order-delivery mode (route shop → the order's stored coordinates).
class DeliveryMapArgs {
  final LatLng destination;
  final String? destinationLabel;
  final String? title;

  const DeliveryMapArgs({
    required this.destination,
    this.destinationLabel,
    this.title,
  });

  /// Builds args from route arguments. Returns null when coordinates are absent
  /// (manually-typed address) so the caller stays in store-locator mode.
  static DeliveryMapArgs? fromRouteArguments(Object? args) {
    if (args is! Map) return null;
    final lat = (args['latitude'] as num?)?.toDouble();
    final lng = (args['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return DeliveryMapArgs(
      destination: LatLng(lat, lng),
      destinationLabel: args['label'] as String?,
      title: args['title'] as String?,
    );
  }
}

/// Whether the order-detail "view delivery route" CTA should show: only a
/// shipping order that carries stored coordinates can be mapped.
bool deliveryRouteCtaVisible(
  OrderStatus status,
  double? latitude,
  double? longitude,
) {
  return status == OrderStatus.shipping &&
      latitude != null &&
      longitude != null;
}
