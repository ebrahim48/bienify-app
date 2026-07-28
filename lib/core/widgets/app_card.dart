import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';

/// White content surface used by every card on the Home feed.
///
/// Wraps the shared radius, hairline border and soft shadow so cards cannot
/// drift apart visually.
///
/// ```dart
/// AppCard(child: Column(children: [...]))
/// AppCard(onTap: c.openRequest, padding: EdgeInsets.all(12), child: ...)
/// ```
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.radius = AppRadius.xl,
    this.color = AppColors.surface,
    this.borderColor = AppColors.surfaceBorder,
    this.hasShadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double radius;
  final Color color;
  final Color borderColor;
  final bool hasShadow;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius.r);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor, width: AppSizes.borderWidth),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: AppColors.gray900.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: AppColors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding:
                padding ??
                EdgeInsets.symmetric(
                  horizontal: AppSpacing.base.w,
                  vertical: AppSpacing.sm.h,
                ),
            child: child,
          ),
        ),
      ),
    );
  }
}
