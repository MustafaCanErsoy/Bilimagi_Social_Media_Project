import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Bilimagi v7.0 Typography System
/// Poppins-based modern typography
class AppTypography {
  AppTypography._();

  // ============ Display & Headlines ============
  static TextStyle get display => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  static TextStyle get h1 => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.3,
      );

  static TextStyle get h2 => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get h3 => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  // ============ Body Text ============
  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get body => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  // ============ UI Elements ============
  static TextStyle get caption => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.3,
      );

  static TextStyle get button => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.0,
      );

  static TextStyle get label => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  // ============ Logo Typography ============
  static TextStyle get logo => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      );

  static TextStyle get logoSmall => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      );

  static TextStyle get slogan => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      );

  // ============ Text Theme for Material ============
  static TextTheme textTheme({required bool isDark}) {
    final Color textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final Color textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final Color textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return TextTheme(
      displayLarge: display.copyWith(color: textPrimary),
      displayMedium: h1.copyWith(color: textPrimary),
      displaySmall: h2.copyWith(color: textPrimary),
      headlineMedium: h2.copyWith(color: textPrimary),
      headlineSmall: h3.copyWith(color: textPrimary),
      titleLarge: h3.copyWith(color: textPrimary),
      titleMedium: bodyLarge.copyWith(
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleSmall: body.copyWith(
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: bodyLarge.copyWith(color: textPrimary),
      bodyMedium: body.copyWith(color: textPrimary),
      bodySmall: bodySmall.copyWith(color: textSecondary),
      labelLarge: button.copyWith(color: textPrimary),
      labelMedium: label.copyWith(color: textSecondary),
      labelSmall: caption.copyWith(color: textMuted),
    );
  }
}
