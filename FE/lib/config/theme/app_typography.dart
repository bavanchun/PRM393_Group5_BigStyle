import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get displayLarge => GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1A1A),
        height: 1.2,
      );

  static TextStyle get displayMedium => GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1A1A),
        height: 1.25,
      );

  static TextStyle get displaySmall => GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1A1A),
        height: 1.3,
      );

  static TextStyle get headlineLarge => GoogleFonts.dmSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1A1A),
        height: 1.3,
      );

  static TextStyle get headlineMedium => GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1A1A),
        height: 1.35,
      );

  static TextStyle get headlineSmall => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1A1A),
        height: 1.4,
      );

  static TextStyle get bodyLarge => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF1A1A1A),
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF1A1A1A),
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF6B6B6B),
        height: 1.4,
      );

  static TextStyle get labelLarge => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1A1A),
        height: 1.3,
      );

  static TextStyle get labelSmall => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF6B6B6B),
        height: 1.3,
        letterSpacing: 0.3,
      );

  static TextStyle get caption => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFA0A0A0),
        height: 1.3,
      );

  static TextStyle get button => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.2,
        letterSpacing: 0.5,
      );

  static TextStyle get price => GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: const Color(0xFFC4517A),
        height: 1.2,
      );

  static TextStyle get priceSmall => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: const Color(0xFFC4517A),
        height: 1.2,
      );
}
