import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Spacing tokens (`space`, 15 tokens) from the Bienify token board.
///
/// Values are design-size pixels; call `.h` / `.w` (or use [gapV] / [gapH])
/// when turning them into real layout so spacing scales with the device.
class AppSpacing {
  AppSpacing._();

  static const double zero = 0;
  static const double px = 1;
  static const double xxs = 2;
  static const double xs2 = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double base = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 28;
  static const double xl2 = 32;
  static const double xl3 = 40;
  static const double xl4 = 48;
  static const double xl5 = 60;
  static const double xl6 = 72;

  /// Horizontal page gutter used by every auth / onboarding screen
  /// (390 − 2×16 = 358, the width every button and field is drawn at).
  static const double screenPadding = base;

  /// Vertical space between the app bar and the first element of a screen.
  static const double screenTop = lg;

  /// Vertical gap between a field label and its input.
  static const double labelGap = xs;

  /// Vertical gap between two labelled form groups.
  static const double fieldGap = md;

  // ─── Gap helpers ─────────────────────────────────────────────────────────

  /// Vertical gap of [value] design-pixels.
  static Widget gapV(double value) => SizedBox(height: value.h);

  /// Horizontal gap of [value] design-pixels.
  static Widget gapH(double value) => SizedBox(width: value.w);

  /// Symmetric page padding shared by all auth screens.
  static EdgeInsets get pagePadding =>
      EdgeInsets.symmetric(horizontal: screenPadding.w);
}
