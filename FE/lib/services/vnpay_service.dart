import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Result of asking the BigStyle BE to mint a VNPay payment URL.
class VnpayCreateResult {
  const VnpayCreateResult({
    required this.paymentUrl,
    required this.transactionId,
    required this.orderId,
  });

  final String paymentUrl;
  final String transactionId;
  final String orderId;

  factory VnpayCreateResult.fromJson(Map<String, dynamic> json) {
    return VnpayCreateResult(
      paymentUrl: json['paymentUrl'] as String,
      transactionId: json['transactionId'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
    );
  }
}

/// Thin HTTP client for the BE VNPay endpoints.
/// Signature generation stays server-side — the app never sees VNP_HASHSECRET.
class VnpayService {
  VnpayService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Creates (or reuses) a pending `payments` row and returns the VNPay URL.
  Future<VnpayCreateResult> createPayment({
    required String orderId,
    required double amount,
    String? orderNumber,
    String? returnUrl,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/payments/vnpay-create');
    final body = <String, dynamic>{
      'orderId': orderId,
      'amount': amount.round(),
      if (orderNumber != null && orderNumber.isNotEmpty) 'orderNumber': orderNumber,
      'returnUrl': returnUrl ?? AppConfig.vnpayReturnUrl,
    };

    final response = await _client
        .post(
          uri,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
        'VNPay create failed (HTTP ${response.statusCode}): invalid response',
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded['success'] != true) {
      final message = decoded['message'] as String? ??
          'Không tạo được link thanh toán VNPay';
      throw Exception(message);
    }

    final paymentUrl = decoded['paymentUrl'] as String?;
    if (paymentUrl == null || paymentUrl.isEmpty) {
      throw Exception('VNPay create returned empty paymentUrl');
    }

    return VnpayCreateResult.fromJson(decoded);
  }
}
