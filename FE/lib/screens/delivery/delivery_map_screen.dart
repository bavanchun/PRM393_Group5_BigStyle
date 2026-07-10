import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../config/app_config.dart';

class DeliveryMapScreen extends StatefulWidget {
  const DeliveryMapScreen({super.key});

  @override
  State<DeliveryMapScreen> createState() => _DeliveryMapScreenState();
}

class _DeliveryMapScreenState extends State<DeliveryMapScreen> {
  GoogleMapController? _mapController;
  static const LatLng _shopLocation = LatLng(10.7758, 106.7048);
  LatLng? _customerLocation;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _routePoints = [];
  bool _isLoading = true;
  double _distanceKm = 0;
  bool _usePulseIcon = false;
  Timer? _pulseTimer;
  BitmapDescriptor? _shopIcon;
  BitmapDescriptor? _customerIconNormal;
  BitmapDescriptor? _customerIconPulse;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _customerLocation = LatLng(position.latitude, position.longitude);
    } catch (_) {
      _customerLocation = const LatLng(10.7728, 106.7018);
    }

    await _createMarkerIcons();
    await _calculateRoute();
    _setMarkers();
    _startPulse();
    setState(() => _isLoading = false);
    _animateToBounds();
  }

  Future<void> _createMarkerIcons() async {
    _shopIcon = await _buildShopMarker();
    _customerIconNormal = await _buildCustomerMarker(1.0);
    _customerIconPulse = await _buildCustomerMarker(1.35);
  }

  Future<BitmapDescriptor> _buildShopMarker() async {
    final size = 48;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint()..color = AppColors.primary;
    canvas.drawCircle(const Offset(24, 24), 20, paint);

    final whitePaint = Paint()
      ..color = AppColors.onPrimary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(24, 24), 16, whitePaint);

    final textBuilder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: TextAlign.center,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          )
          ..pushStyle(ui.TextStyle(color: AppColors.primary))
          ..addText('B');
    final paragraph = textBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: 32));
    canvas.drawParagraph(paragraph, const Offset(8, 11));

    final image = await recorder.endRecording().toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _buildCustomerMarker(double scale) async {
    final s = (48 * scale).round();
    final half = s / 2;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final bgPaint = Paint()..color = AppColors.primary.withValues(alpha: 0.15);
    canvas.drawCircle(Offset(half, half), half, bgPaint);

    final ringPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(half, half), half - 2, ringPaint);

    final dotPaint = Paint()..color = AppColors.primary;
    canvas.drawCircle(Offset(half, half), 8, dotPaint);

    final innerPaint = Paint()..color = AppColors.onPrimary;
    canvas.drawCircle(Offset(half, half), 4, innerPaint);

    final image = await recorder.endRecording().toImage(s, s);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  void _startPulse() {
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (!mounted) return;
      _usePulseIcon = !_usePulseIcon;
      _setMarkers();
    });
  }

  Future<void> _calculateRoute() async {
    if (_customerLocation == null) return;

    final apiKey = AppConfig.googleMapsApiKey;
    if (apiKey.isNotEmpty) {
      try {
        final url =
            'https://maps.googleapis.com/maps/api/directions/json'
            '?origin=${_shopLocation.latitude},${_shopLocation.longitude}'
            '&destination=${_customerLocation!.latitude},${_customerLocation!.longitude}'
            '&key=$apiKey';
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'OK') {
            final leg = data['routes'][0]['legs'][0];
            _distanceKm = (leg['distance']['value'] / 1000.0);
            _routePoints = _decodePolyline(
              data['routes'][0]['overview_polyline']['points'],
            );
            _updatePolyline();
            return;
          }
        }
      } catch (_) {}
    }

    _routePoints = [_shopLocation, _customerLocation!];
    _distanceKm = _calculateDistance(_shopLocation, _customerLocation!);
    _updatePolyline();
  }

  List<LatLng> _decodePolyline(String encoded) {
    final poly = <LatLng>[];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  void _updatePolyline() {
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: _routePoints,
          color: AppColors.primary,
          width: 4,
          jointType: JointType.round,
          geodesic: true,
        ),
      };
    });
  }

  double _calculateDistance(LatLng a, LatLng b) {
    const p = 0.017453292519943295;
    final a1 =
        0.5 -
        cos((b.latitude - a.latitude) * p) / 2 +
        cos(a.latitude * p) *
            cos(b.latitude * p) *
            (1 - cos((b.longitude - a.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a1));
  }

  void _setMarkers() {
    if (_customerLocation == null ||
        _shopIcon == null ||
        _customerIconNormal == null) {
      return;
    }
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('shop'),
          position: _shopLocation,
          icon: _shopIcon!,
          anchor: const Offset(0.5, 0.5),
          infoWindow: const InfoWindow(
            title: 'BigStyle Shop',
            snippet: '123 Nguyễn Huệ, Q.1, TP.HCM',
          ),
        ),
        Marker(
          markerId: const MarkerId('customer'),
          position: _customerLocation!,
          icon: _usePulseIcon ? _customerIconPulse! : _customerIconNormal!,
          anchor: const Offset(0.5, 0.5),
          infoWindow: const InfoWindow(title: 'Vị trí của bạn'),
        ),
      };
    });
  }

  void _animateToBounds() {
    if (_customerLocation == null) return;
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        _boundsFromLatLngs([_shopLocation, _customerLocation!]),
        100,
      ),
    );
  }

  LatLngBounds _boundsFromLatLngs(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;
    for (final p in points) {
      minLat = minLat == null ? p.latitude : min(minLat, p.latitude);
      maxLat = maxLat == null ? p.latitude : max(maxLat, p.latitude);
      minLng = minLng == null ? p.longitude : min(minLng, p.longitude);
      maxLng = maxLng == null ? p.longitude : max(maxLng, p.longitude);
    }
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  // Phí ship phải khớp với phí flat thực thu ở checkout
  // (AppConfig.flatShippingFee); không hiển thị mức tính theo khoảng cách mà hệ
  // thống không bao giờ tính, tránh gây hiểu nhầm cho khách.
  double get shippingFee => AppConfig.flatShippingFee;

  String get estimatedTime {
    if (_distanceKm <= 3) return '15-25 phút';
    if (_distanceKm <= 7) return '25-35 phút';
    if (_distanceKm <= 15) return '35-50 phút';
    return '50-70 phút';
  }

  Future<void> _openGoogleMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${_shopLocation.latitude},${_shopLocation.longitude}',
    );
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw Exception('launchUrl returned false');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể mở Google Maps'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _goToMyLocation() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final loc = LatLng(position.latitude, position.longitude);
      setState(() => _customerLocation = loc);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 15));
      await _calculateRoute();
      _setMarkers();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Không thể lấy vị trí hiện tại'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_customerLocation != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _customerLocation!,
                zoom: 13,
              ),
              onMapCreated: (controller) => _mapController = controller,
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              padding: const EdgeInsets.only(bottom: 220),
            )
          else
            const Center(child: CircularProgressIndicator()),
          Positioned(
            right: 16,
            bottom: 240,
            child: FloatingActionButton.small(
              onPressed: _goToMyLocation,
              backgroundColor: AppColors.surface,
              child: const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.surface,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          _buildBottomSheet(),
          if (_isLoading)
            ColoredBox(
              color: AppColors.shadow.withValues(alpha: 0.26),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.store,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BigStyle Shop',
                            style: AppTypography.headlineSmall.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '123 Nguyễn Huệ, Q.1, TP.HCM',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_distanceKm.toStringAsFixed(1)} km',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _buildInfoItem(
                        Icons.timer_outlined,
                        'Thời gian',
                        estimatedTime,
                      ),
                      _buildInfoDivider(),
                      _buildInfoItem(
                        Icons.motorcycle_outlined,
                        'Phí ship',
                        '${shippingFee.toStringAsFixed(0)}đ',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _openGoogleMaps,
                    icon: const Icon(Icons.directions, color: AppColors.onPrimary),
                    label: Text(
                      'Chỉ đường',
                      style: TextStyle(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 6),
          Text(label, style: AppTypography.caption.copyWith(fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.labelLarge.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDivider() {
    return Container(width: 1, height: 40, color: AppColors.divider);
  }
}
