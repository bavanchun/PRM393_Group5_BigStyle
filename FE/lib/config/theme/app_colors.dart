import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF9A3F35);
  static const Color primaryDark = Color(0xFF742E28);
  static const Color secondary = Color(0xFFE8C9A0);
  static const Color accent = Color(0xFF2F2A28);
  static const Color background = Color(0xFFFBF6EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFC0392B);

  static const Color textPrimary = Color(0xFF2A211E);
  static const Color textSecondary = Color(0xFF746159);
  static const Color textHint = Color(0xFFA99589);
  static const Color border = Color(0xFFEAD9C7);
  static const Color divider = Color(0xFFF3E9DD);
  static const Color success = Color(0xFF2E6B47);
  static const Color warning = Color(0xFF8A5313);

  // Additive v2 tokens (docs/design-tokens-v2.md changelog) — named aliases
  // for the ~130 legitimate white-on-primary / shadow usages that had no
  // semantic token before the reskin.
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color shadow = Color(0xFF000000);

  // Shimmer/skeleton-loading placeholder tones — warm-neutral counterparts
  // to Colors.grey[200]/[100] (same subtle lightness delta so the sweep
  // animation stays visible) instead of the palette's cool default greys.
  static const Color skeletonBase = Color(0xFFEDE6DD);
  static const Color skeletonHighlight = Color(0xFFF6F1E9);
}
