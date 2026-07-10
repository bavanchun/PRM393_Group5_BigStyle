// ignore_for_file: constant_identifier_names

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
}
