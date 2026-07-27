import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────
  static const Color brand = Color(0xFF2DA44E);

  // ── Neutrals ───────────────────────────────────────────────────────────
  static const Color primary   = Color(0xFF1C1C1E); // primary text / dark bg
  static const Color surface   = Color(0xFFF5F5F7); // page / card bg
  static const Color surfaceSubtle = Color(0xFFECECEF); // dividers, subtle surfaces
  static const Color surfaceMuted  = Color(0xFFF0F0F2); // inactive button fill
  static const Color textSecondary = Color(0xFF8A8A8E); // secondary / caption
  static const Color textDisabled  = Color(0xFFB8B8BD); // disabled / placeholder

  // ── Semantic ───────────────────────────────────────────────────────────
  static const Color error   = Color(0xFFE5484D);
  static const Color warning = Color(0xFFE8A21C);

  // ── Base ───────────────────────────────────────────────────────────────
  static const Color white       = Color(0xFFFFFFFF);
  static const Color black       = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // ── Borders ────────────────────────────────────────────────────────────
  static const Color border = Color(0xFFE6E6E6);

  // ── Shadows ────────────────────────────────────────────────────────────
  static Color shadowLight  = Colors.black.withValues(alpha: 0.05);
  static Color shadowMedium = Colors.black.withValues(alpha: 0.08);

  // ── Shimmer ────────────────────────────────────────────────────────────
  static Color shimmerBase      = const Color(0xFFECECEF);
  static Color shimmerHighlight = const Color(0xFFF5F5F7);

  // ── Legacy aliases (keep for backward compat with existing home widgets) ─
  static const Color background    = Color(0xFFF5F5F7);
  static const Color textPrimary   = Color(0xFF1C1C1E);
  static const Color textHint      = Color(0xFFB8B8BD);
  static const Color divider       = Color(0xFFE6E6E6);
  static const Color rating        = Color(0xFFE8A21C);
  static const Color ratingInactive = Color(0xFFECECEF);
  static Color? shimmerContainer   = const Color(0xFFECECEF);
  static Color grey400 = const Color(0xFFB8B8BD);
  static Color grey600 = const Color(0xFF8A8A8E);
  static Color grey700 = const Color(0xFF636366);
  static Color shadowDark = Colors.black.withValues(alpha: 0.25);
  static const Color textBlack87 = Color(0xDD000000);
  static const Color textDark    = Color(0xFF1C1C1E);
  static const Color textGray    = Color(0xFF8A8A8E);
  static const Color textLightGray  = Color(0xFFB8B8BD);
  static const Color textMediumGray = Color(0xFF8A8A8E);
  static const Color textDarkGray   = Color(0xFF636366);
  static const Color primaryDark    = Color(0xFF1A6B32);
  static const Color primaryLight   = Color(0xFF5BC47A);
  static const Color greenAccent      = Color(0xFF2DA44E);
  static const Color greenAccentLight = Color(0xFF5BC47A);
  static const Color bannerPeach = Color(0xFFF8CCAD);
  static const Color red = Color(0xFFE5484D);
}
