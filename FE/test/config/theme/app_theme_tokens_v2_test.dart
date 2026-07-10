import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bigstyle_app/config/theme/app_colors.dart';
import 'package:bigstyle_app/config/theme/app_spacing.dart';
import 'package:bigstyle_app/config/theme/app_typography.dart';
import 'package:bigstyle_app/config/theme/app_theme.dart';
import 'package:bigstyle_app/config/theme/status_colors.dart';

void main() {
  group('AppColors v2 values', () {
    test('core palette matches docs/design-tokens-v2.md', () {
      expect(AppColors.primary, const Color(0xFF9A3F35));
      expect(AppColors.primaryDark, const Color(0xFF742E28));
      expect(AppColors.secondary, const Color(0xFFE8C9A0));
      expect(AppColors.accent, const Color(0xFF2F2A28));
      expect(AppColors.background, const Color(0xFFFBF6EF));
      expect(AppColors.surface, const Color(0xFFFFFFFF));
      expect(AppColors.error, const Color(0xFFC0392B));
      expect(AppColors.success, const Color(0xFF2E6B47));
      expect(AppColors.warning, const Color(0xFF8A5313));
      expect(AppColors.textPrimary, const Color(0xFF2A211E));
      expect(AppColors.textSecondary, const Color(0xFF746159));
      expect(AppColors.textHint, const Color(0xFFA99589));
      expect(AppColors.border, const Color(0xFFEAD9C7));
      expect(AppColors.divider, const Color(0xFFF3E9DD));
    });

    test('additive tokens present', () {
      expect(AppColors.onPrimary, const Color(0xFFFFFFFF));
      expect(AppColors.shadow, const Color(0xFF000000));
    });
  });

  group('AppSpacing v2 radii', () {
    test('shape scale matches docs/design-tokens-v2.md', () {
      expect(AppSpacing.cardRadius, 20);
      expect(AppSpacing.buttonRadius, 14);
      expect(AppSpacing.bottomSheetRadius, 28);
      expect(AppSpacing.inputRadius, 14);
      expect(AppSpacing.chipRadius, 24);
    });

    test('spacing scale unchanged from v1', () {
      expect(AppSpacing.xxs, 4);
      expect(AppSpacing.xs, 8);
      expect(AppSpacing.sm, 12);
      expect(AppSpacing.md, 16);
      expect(AppSpacing.lg, 24);
      expect(AppSpacing.xl, 32);
      expect(AppSpacing.xxl, 48);
    });
  });

  group('AppTypography font families', () {
    test('display styles use Cormorant', () {
      expect(AppTypography.displayLarge.fontFamily, 'Cormorant');
      expect(AppTypography.displayMedium.fontFamily, 'Cormorant');
      expect(AppTypography.displaySmall.fontFamily, 'Cormorant');
    });

    test('body/UI styles use Montserrat', () {
      for (final style in [
        AppTypography.headlineLarge,
        AppTypography.headlineMedium,
        AppTypography.headlineSmall,
        AppTypography.bodyLarge,
        AppTypography.bodyMedium,
        AppTypography.bodySmall,
        AppTypography.labelLarge,
        AppTypography.labelSmall,
        AppTypography.caption,
        AppTypography.button,
        AppTypography.price,
        AppTypography.priceSmall,
      ]) {
        expect(style.fontFamily, 'Montserrat');
      }
    });
  });

  group('AppTheme wiring', () {
    final theme = AppTheme.light;

    test('ColorScheme resolves v2 tokens (not fromSeed-derived)', () {
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.onPrimary, AppColors.onPrimary);
      expect(theme.colorScheme.secondary, AppColors.secondary);
      expect(theme.colorScheme.error, AppColors.error);
    });

    test('StatusColors extension is registered with correct tones', () {
      final statusColors = theme.extension<StatusColors>();
      expect(statusColors, isNotNull);
      expect(statusColors!.success, AppColors.success);
      expect(statusColors.warning, AppColors.warning);
      expect(statusColors.error, AppColors.error);
      expect(statusColors.info, isNot(AppColors.primary));
    });

    test('chip selected state resolves tonal (primary text, not white)', () {
      final labelStyle = theme.chipTheme.labelStyle!;
      final selectedColor = WidgetStateProperty.resolveAs<Color?>(
        labelStyle.color,
        <WidgetState>{WidgetState.selected},
      );
      final unselectedColor = WidgetStateProperty.resolveAs<Color?>(
        labelStyle.color,
        <WidgetState>{},
      );
      expect(selectedColor, AppColors.primary);
      expect(unselectedColor, AppColors.textSecondary);
      expect(selectedColor, isNot(Colors.white));
    });
  });
}
