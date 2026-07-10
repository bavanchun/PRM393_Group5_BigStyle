import 'package:flutter/material.dart';

/// Manager-facing product color swatch options (real garment colors a
/// manager can assign to a product) — not part of the app's own UI brand
/// palette in `config/theme/`, so these stay separate from `AppColors`.
/// Shared between manager_product_detail_screen.dart and
/// manager_create_product_screen.dart, which previously each duplicated
/// this same map.
class ProductSwatchColors {
  ProductSwatchColors._();

  static const Color datNung = Color(0xFF914B34);
  static const Color xanhNgoc = Color(0xFF2A6767);
  static const Color den = Color(0xFF313030);

  static const Map<String, String> hexByName = {
    'Đất nung': '#914B34',
    'Xanh ngọc': '#2A6767',
    'Đen': '#313030',
  };
}
