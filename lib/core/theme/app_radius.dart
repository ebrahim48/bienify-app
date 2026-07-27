import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Corner-radius tokens (`radius`, 10 tokens) from the Bienify token board.
///
/// Use the `BorderRadius` helpers below rather than calling
/// `BorderRadius.circular(...)` with a literal, so every rounded surface in
/// the app stays on the scale.
class AppRadius {
  AppRadius._();

  static const double none = 0;
  static const double sm = 2;
  static const double md = 4;
  static const double lg = 8;
  static const double xl = 12;
  static const double xl2 = 16;
  static const double xl3 = 24;
  static const double xl4 = 32;
  static const double xl5 = 48;
  static const double full = 999;

  // ─── Ready-made BorderRadius (responsive) ────────────────────────────────

  static BorderRadius get rSm => BorderRadius.circular(sm.r);
  static BorderRadius get rMd => BorderRadius.circular(md.r);
  static BorderRadius get rLg => BorderRadius.circular(lg.r);
  static BorderRadius get rXl => BorderRadius.circular(xl.r);
  static BorderRadius get rXl2 => BorderRadius.circular(xl2.r);
  static BorderRadius get rXl3 => BorderRadius.circular(xl3.r);
  static BorderRadius get rXl4 => BorderRadius.circular(xl4.r);
  static BorderRadius get rXl5 => BorderRadius.circular(xl5.r);
  static BorderRadius get rFull => BorderRadius.circular(full);
}
