import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// MODELS
// ---------------------------------------------------------------------------
class FlashSaleProduct {
  final String id;
  final String name;
  final String imageUrl;
  final int salePrice;
  final int originalPrice;
  final int stockQty;
  final int soldQty;
  final List<String> sizes;

  FlashSaleProduct({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.salePrice,
    required this.originalPrice,
    required this.stockQty,
    required this.soldQty,
    required this.sizes,
  });

  double get soldPercent => stockQty == 0 ? 0 : (soldQty / stockQty).clamp(0, 1);
  bool get isSoldOut => soldQty >= stockQty;
  bool get onSale => salePrice < originalPrice;

  factory FlashSaleProduct.fromJson(Map<String, dynamic> json) {
    return FlashSaleProduct(
      id: json['id'].toString(),
      name: json['name'] as String,
      imageUrl: json['image_url'] as String,
      salePrice: json['sale_price'] as int,
      originalPrice: json['original_price'] as int,
      stockQty: json['stock_qty'] as int,
      soldQty: json['sold_qty'] as int,
      sizes: List<String>.from(json['sizes'] ?? []),
    );
  }
}

class FlashSaleCampaign {
  final String id;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final List<FlashSaleProduct> products;

  FlashSaleCampaign({
    required this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.products,
  });

  factory FlashSaleCampaign.fromJson(Map<String, dynamic> json) {
    return FlashSaleCampaign(
      id: json['id'].toString(),
      title: json['title'] as String,
      startAt: DateTime.parse(json['start_at'] as String),
      endAt: DateTime.parse(json['end_at'] as String),
      products: (json['products'] as List)
          .map((p) => FlashSaleProduct.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// PROVIDER
// ---------------------------------------------------------------------------
class FlashSaleProvider extends ChangeNotifier {
  FlashSaleCampaign? campaign;
  Duration remaining = Duration.zero;
  bool isLoading = false;
  bool hasEnded = false;
  String? error;

  Duration _serverOffset = Duration.zero;
  Timer? _tickTimer;
  Timer? _resyncTimer;

  String get apiBaseUrl {
    final envUrl = dotenv.env['FLASH_SALE_API_URL']?.trim();
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;

    if (!kIsWeb && Platform.isAndroid) {
      // Android emulator: use host localhost via 10.0.2.2
      return 'http://10.0.2.2:3001';
    }

    return const String.fromEnvironment(
      'FLASH_SALE_API_URL',
      defaultValue: 'http://localhost:3001',
    );
  }

  Future<void> init() async {
    await _resync();
    _resyncTimer = Timer.periodic(const Duration(seconds: 25), (_) => _resync());
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _resync() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/api/flash-sale/current'));
      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final serverTime = DateTime.parse(body['server_time'] as String);
      _serverOffset = serverTime.difference(DateTime.now());

      final campaignJson = body['campaign'] as Map<String, dynamic>?;
      if (campaignJson != null) {
        final productsList = (body['products'] as List)
            .map((p) => FlashSaleProduct.fromJson(p as Map<String, dynamic>))
            .toList();
        campaign = FlashSaleCampaign.fromJson({
          ...campaignJson,
          'products': body['products'],
        });
        // Gán products đã parse
        campaign = FlashSaleCampaign(
          id: campaignJson['id'].toString(),
          title: campaignJson['title'] as String,
          startAt: DateTime.parse(campaignJson['start_at'] as String),
          endAt: DateTime.parse(campaignJson['end_at'] as String),
          products: productsList,
        );
      } else {
        campaign = null;
      }

      hasEnded = false;
      error = null;
      _tick();
    } catch (e) {
      error = e.toString();
      debugPrint('FlashSale resync error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _tick() {
    final c = campaign;
    if (c == null) return;

    final correctedNow = DateTime.now().add(_serverOffset);
    final diff = c.endAt.difference(correctedNow);

    if (diff.isNegative) {
      remaining = Duration.zero;
      hasEnded = true;
      _tickTimer?.cancel();
    } else {
      remaining = diff;
    }
    notifyListeners();
  }

  String get formattedCountdown {
    final h = remaining.inHours.toString().padLeft(2, '0');
    final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _resyncTimer?.cancel();
    super.dispose();
  }
}
