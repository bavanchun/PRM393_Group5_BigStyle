import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Additive Material 3 theme extension (docs/design-tokens-v2.md changelog).
/// `ColorScheme` has no success/warning/info slots, so tonal status UI
/// (StatusBadge, stat cards) resolves through this instead of ad hoc
/// per-screen color maps.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  const StatusColors({
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
  });

  static const StatusColors standard = StatusColors(
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    info: Color(0xFF2E5F8A),
  );

  @override
  StatusColors copyWith({
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
  }) {
    return StatusColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
    );
  }

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}
