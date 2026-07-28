import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_sizes.dart';

/// Renders an SVG from `assets/icons` at a design size, optionally recoloured.
///
/// The exported icons carry hard-coded fills, so passing [color] applies a
/// `srcIn` filter over the whole drawing — which is what lets one file serve
/// both the active and inactive states of the bottom navigation.
///
/// ```dart
/// AppSvgIcon(AppIcons.notification)                       // as exported
/// AppSvgIcon(AppIcons.home, color: AppColors.actionFill)  // tinted
/// AppSvgIcon(AppIcons.heart, size: 28, color: AppColors.primary500)
/// ```
class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon(
    this.asset, {
    super.key,
    this.size = AppSizes.xl2,
    this.color,
    this.semanticsLabel,
  });

  final String asset;

  /// Edge length in design pixels; scaled with the device.
  final double size;

  /// When null the icon keeps the colours it was exported with.
  final Color? color;

  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size.w,
      height: size.w,
      fit: BoxFit.contain,
      semanticsLabel: semanticsLabel,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}
