// ignore_for_file: constant_identifier_names

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static String get googleMapsApiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  static String get googleWebClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';

  /// SePay bank name/code (e.g. Vietcombank, MBBank) used to build the VietQR image URL.
  static String get sepayBank => dotenv.env['SEPAY_BANK'] ?? '';

  /// Bank account number linked to the SePay account.
  static String get sepayAcc => dotenv.env['SEPAY_ACC'] ?? '';

  /// Flat shipping fee (VND) actually charged at checkout. Single source of
  /// truth so the delivery-map preview and the checkout total never diverge.
  static const double flatShippingFee = 30000;

  /// BigStyle Node API base URL (flash-sale + VNPay). Falls back to emulator
  /// / localhost defaults when FLASH_SALE_API_URL is unset.
  static String get apiBaseUrl {
    final envUrl = dotenv.env['FLASH_SALE_API_URL']?.trim();
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;

    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3001';
    }

    return const String.fromEnvironment(
      'FLASH_SALE_API_URL',
      defaultValue: 'http://localhost:3001',
    );
  }

  /// Absolute VNPay return URL the gateway redirects to after payment.
  /// Prefer VNP_RETURN_URL from .env (public/ngrok URL); otherwise derive
  /// from [apiBaseUrl] (works for emulator → host loopback).
  static String get vnpayReturnUrl {
    final fromEnv = dotenv.env['VNP_RETURN_URL']?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return '$apiBaseUrl/api/payments/vnpay-return';
  }
}
