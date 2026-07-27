import 'package:flutter/material.dart';
import 'app_colors.dart';

/// The complete Bienify type scale.
///
/// Sizes are declared in logical pixels at the 390×876 design size; screens
/// scale them at build time with `.sp` (see `AppTextStylesX.r`), so a style is
/// never redefined per-screen. If a screen needs a one-off tweak prefer
/// `copyWith` over adding a new token.
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Satoshi';

  // =========================
  // Display
  // =========================

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 57,
    fontWeight: FontWeight.w700,
    height: 64 / 57,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 45,
    fontWeight: FontWeight.w700,
    height: 52 / 45,
    color: AppColors.textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 44 / 36,
    color: AppColors.textPrimary,
  );

  // =========================
  // Headline
  // =========================

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 36 / 28,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
    color: AppColors.textPrimary,
  );

  // =========================
  // Title
  // =========================

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 28 / 22,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 22 / 16,
    color: AppColors.textPrimary,
  );

  // =========================
  // Body
  // =========================

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 18 / 12,
    color: AppColors.textSecondary,
  );

  // =========================
  // Label
  // =========================

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 14 / 10,
    color: AppColors.textSecondary,
  );

  // =========================
  // Button
  // =========================

  static const TextStyle buttonLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    color: Colors.white,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    color: Colors.white,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 18 / 12,
    color: Colors.white,
  );

  // =========================
  // Caption & Overline
  // =========================

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1,
    color: AppColors.textSecondary,
  );
}
