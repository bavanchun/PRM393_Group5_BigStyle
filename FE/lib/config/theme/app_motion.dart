import 'package:flutter/material.dart';

/// Motion tokens from docs/design-tokens-v2.md (easeOutCubic, 250-300ms) —
/// specified during the v2 reskin but never wired into code until now.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);

  static const Curve entrance = Curves.easeOutCubic;
  static const Curve standard = Curves.easeInOut;

  /// Per-item delay for staggered entrance sequences.
  static const Duration stagger = Duration(milliseconds: 60);
}
