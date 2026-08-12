import 'package:flutter/material.dart';
import 'app_colors.dart';

/// The complete Bienify type scale.
///
/// Every style carries the design-system token it comes from, read off
/// `Design System Color ,Font and BG/Text Styles.svg`. The names here are
/// Material's because that is what `TextTheme` wants; the metrics are the
/// design system's:
///
/// | here            | token             | size / line-height |
/// |-----------------|-------------------|--------------------|
/// | displayLarge    | Heading/H1        | 56 / 68            |
/// | displayMedium   | Heading/H2        | 48 / 58            |
/// | displaySmall    | Heading/H3        | 40 / 48            |
/// | headlineLarge   | Heading/H4        | 32 / 38            |
/// | headlineSmall   | Heading/H5        | 24 / 30            |
/// | titleLarge      | Heading/H6        | 20 / 24            |
/// | titleMedium     | Body/Body-1       | 18 / 28            |
/// | titleSmall      | Body/Body-2       | 16 / 24            |
/// | bodyLarge       | Body/Body-2       | 16 / 24            |
/// | bodyMedium      | Body/Body-3       | 14 / 20            |
/// | bodySmall       | Body/Body-4       | 12 / 16            |
/// | labelLarge      | Body/Body-3       | 14 / 20            |
/// | labelMedium     | Body/Body-4       | 12 / 16            |
/// | labelSmall      | Caption/Caption-1 | 10 / 12            |
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
    // Heading/H1
    fontSize: 56,
    fontWeight: FontWeight.w700,
    height: 68 / 56,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    // Heading/H2
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 58 / 48,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    // Heading/H3
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 48 / 40,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  // =========================
  // Headline
  // =========================

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    // Heading/H4
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 38 / 32,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  /// The one step with no design token behind it.
  ///
  /// The system jumps H4 (32) straight to H5 (24); this sits between them and
  /// ten screens use it. Its metrics follow the ratio the neighbours set —
  /// 1.19 at H4, 1.25 at H5 — rather than being invented, but a designer
  /// should rule on whether it stays or the ten sites move to H4 or H5.
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 34 / 28,
    letterSpacing: -0.18,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    // Heading/H5
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 30 / 24,
    letterSpacing: -0.15,
    color: AppColors.textPrimary,
  );

  // =========================
  // Title
  // =========================

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    // Heading/H6
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 24 / 20,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    // Body/Body-1
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 28 / 18,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    // Body/Body-2
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    color: AppColors.textPrimary,
  );

  // =========================
  // Body
  // =========================

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    // Body/Body-2
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    // Body/Body-3
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    // Body/Body-4
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    color: AppColors.textSecondary,
  );

  // =========================
  // Label
  // =========================

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    // Body/Body-3
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    // Body/Body-4
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    // Caption/Caption-1
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 12 / 10,
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
