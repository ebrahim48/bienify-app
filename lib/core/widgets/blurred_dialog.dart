import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Presents [child] over a blurred, dimmed copy of the screen behind it.
///
/// `showDialog`'s barrier only tints; the designs blur the page underneath.
/// This uses `showGeneralDialog` with a transparent barrier and a
/// `BackdropFilter` so the real blur happens, and animates the blur in rather
/// than snapping to it.
///
/// ```dart
/// final reason = await showBlurredDialog<String>(
///   context: context,
///   builder: (_) => CancelReasonDialog(...),
/// );
/// ```
Future<T?> showBlurredDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  double sigma = 6,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    // Transparent: the dim comes from the filtered layer below so it sits
    // *behind* the blur rather than on top of it.
    barrierColor: AppColors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, _, _) => builder(context),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      );
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: sigma * curved.value,
          sigmaY: sigma * curved.value,
        ),
        child: ColoredBox(
          color: AppColors.gray50.withValues(alpha: 0.45 * curved.value),
          child: FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

/// The white card every blurred dialog sits in.
class AppDialogCard extends StatelessWidget {
  const AppDialogCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl2.r),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: padding ?? EdgeInsets.all(AppSpacing.md.w),
            child: child,
          ),
        ),
      ),
    );
  }
}
