import 'package:flutter/material.dart';
import 'app_colors.dart';

/// All text styles use the locally bundled "Instrument Sans" font.
/// Weights available: 500 (Medium), 600 (SemiBold), 700 (Bold).
class AppTextStyles {
  AppTextStyles._();

  static const String _font = 'Instrument Sans';

  // ── Headings ───────────────────────────────────────────────────────────
  static const TextStyle h1 = TextStyle(
    fontFamily: _font, fontSize: 44, fontWeight: FontWeight.w700,
    color: AppColors.primary, height: 1.2,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: _font, fontSize: 34, fontWeight: FontWeight.w700,
    color: AppColors.primary, height: 1.2,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: _font, fontSize: 28, fontWeight: FontWeight.w700,
    color: AppColors.primary, height: 1.3,
  );
  static const TextStyle h4 = TextStyle(
    fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w600,
    color: AppColors.primary, height: 1.3,
  );
  static const TextStyle h5 = TextStyle(
    fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.primary, height: 1.4,
  );

  // ── Subtitles ──────────────────────────────────────────────────────────
  static const TextStyle sub1 = TextStyle(
    fontFamily: _font, fontSize: 17, fontWeight: FontWeight.w600,
    color: AppColors.primary, height: 1.41,
  );
  static const TextStyle sub2 = TextStyle(
    fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.primary, height: 1.47,
  );
  static const TextStyle sub3 = TextStyle(
    fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w600,
    color: AppColors.primary, height: 1.54,
  );
  static const TextStyle sub4 = TextStyle(
    fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w600,
    color: AppColors.primary, height: 1.64,
  );
  static const TextStyle sub5 = TextStyle(
    fontFamily: _font, fontSize: 9.5, fontWeight: FontWeight.w600,
    color: AppColors.primary, height: 1.68,
  );

  // ── Body ───────────────────────────────────────────────────────────────
  static const TextStyle body1 = TextStyle(
    fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w500,
    color: AppColors.primary, height: 1.5,
  );
  static const TextStyle body2 = TextStyle(
    fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w500,
    color: AppColors.primary, height: 1.57,
  );
  static const TextStyle body3 = TextStyle(
    fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w500,
    color: AppColors.primary, height: 1.58,
  );
  static const TextStyle body4 = TextStyle(
    fontFamily: _font, fontSize: 10, fontWeight: FontWeight.w500,
    color: AppColors.primary, height: 1.6,
  );

  // ── Button label ───────────────────────────────────────────────────────
  static const TextStyle buttonLabel = TextStyle(
    fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.white, height: 1.5, letterSpacing: 0.1,
  );
}
