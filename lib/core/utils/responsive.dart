import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Turns a design-size [TextStyle] token into a device-scaled one.
///
/// The tokens in `AppTextStyles` are authored at the 390×876 design size.
/// Appending `.r` scales the font (and keeps the token's line-height ratio)
/// so text stays proportional on small phones and tablets alike:
///
/// ```dart
/// Text('Login', style: AppTextStyles.titleMedium.r)
/// Text('Login', style: AppTextStyles.titleMedium.rc(AppColors.authInk))
/// ```
extension ResponsiveTextStyle on TextStyle {
  /// Responsive copy of this style.
  TextStyle get r => copyWith(fontSize: fontSize?.sp);

  /// Responsive copy tinted with [color].
  TextStyle rc(Color color) => copyWith(fontSize: fontSize?.sp, color: color);

  /// Responsive copy with [color] and [weight] overridden.
  TextStyle rw(Color color, FontWeight weight) =>
      copyWith(fontSize: fontSize?.sp, color: color, fontWeight: weight);
}

/// Small helpers for reasoning about the current viewport.
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Bottom inset of the on-screen keyboard.
  double get keyboardInset => MediaQuery.viewInsetsOf(this).bottom;

  bool get isKeyboardOpen => keyboardInset > 0;

  /// True on compact handsets where fixed vertical spacing should compress.
  bool get isCompactHeight => screenHeight < 700;

  /// True on tablets / foldables, where content is centred instead of
  /// stretched edge to edge.
  bool get isTablet => screenWidth >= 600;
}
