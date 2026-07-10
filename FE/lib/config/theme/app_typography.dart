import 'package:flutter/material.dart';
import 'app_colors.dart';

// Cormorant/Montserrat are bundled as local variable-font assets
// (pubspec.yaml `fonts:`) and resolved via plain `fontFamily:` rather than
// the google_fonts package's GoogleFonts.cormorant()/montserrat() API.
// google_fonts validates bundled fonts against its own internal per-weight
// filename convention (e.g. expects an asset literally named
// "Montserrat-SemiBold.ttf") independent of the `family:` declared in
// pubspec.yaml — a single custom-registered variable-font file fails that
// check even though Flutter's own font engine resolves it correctly. Native
// `fontFamily:` has no such check and no network path, so it's fully
// offline-safe by construction.
class AppTypography {
  AppTypography._();

  static const String _display = 'Cormorant';
  static const String _body = 'Montserrat';

  static TextStyle get displayLarge => TextStyle(
        fontFamily: _display,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get displayMedium => TextStyle(
        fontFamily: _display,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  static TextStyle get displaySmall => TextStyle(
        fontFamily: _display,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get headlineLarge => TextStyle(
        fontFamily: _body,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get headlineMedium => TextStyle(
        fontFamily: _body,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.35,
      );

  static TextStyle get headlineSmall => TextStyle(
        fontFamily: _body,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get bodyLarge => TextStyle(
        fontFamily: _body,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontFamily: _body,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySmall => TextStyle(
        fontFamily: _body,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get labelLarge => TextStyle(
        fontFamily: _body,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get labelSmall => TextStyle(
        fontFamily: _body,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.3,
        letterSpacing: 0.3,
      );

  static TextStyle get caption => TextStyle(
        fontFamily: _body,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textHint,
        height: 1.3,
      );

  static TextStyle get button => TextStyle(
        fontFamily: _body,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.onPrimary,
        height: 1.2,
        letterSpacing: 0.5,
      );

  static TextStyle get price => TextStyle(
        fontFamily: _body,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        height: 1.2,
      );

  static TextStyle get priceSmall => TextStyle(
        fontFamily: _body,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        height: 1.2,
      );
}
