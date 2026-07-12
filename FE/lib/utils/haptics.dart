import 'package:flutter/services.dart';

/// Thin wrapper over [HapticFeedback] so call sites read intent
/// (selection / tap / success) instead of a raw platform primitive.
class Haptics {
  Haptics._();

  static void selection() => HapticFeedback.selectionClick();
  static void tap() => HapticFeedback.lightImpact();
  static void success() => HapticFeedback.mediumImpact();
}
