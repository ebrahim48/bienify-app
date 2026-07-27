import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

/// The visual weights a button can take in the Bienify design.
enum AppButtonVariant {
  /// Primary call to action — `primary800` fill (Login, Next, Allow …).
  primary,

  /// Dark secondary action — `primary950` fill (Sign in with Google / Apple).
  dark,

  /// Low-emphasis neutral action — `#E8E8E8` fill (Deny).
  neutral,

  /// Transparent with a 1px outline, for tertiary actions.
  outlined,
}

/// The one button used across the app.
///
/// Geometry comes straight from the spec — 358×50, 24px radius, 18px
/// horizontal / 10px vertical padding, 10px gap between icon and label — and
/// scales with the device through ScreenUtil.
///
/// ```dart
/// AppButton(label: AppStrings.login.tr, onPressed: controller.submit)
///
/// AppButton(
///   label: AppStrings.signInWithGoogle.tr,
///   variant: AppButtonVariant.dark,
///   iconAsset: AppAssets.googleLogo,
///   onPressed: controller.signInWithGoogle,
/// )
/// ```
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.iconAsset,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.expanded = true,
    this.height = AppSizes.controlHeight,
    this.radius = AppRadius.xl3,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;

  /// Optional leading image asset (used for the Google / Apple marks).
  final String? iconAsset;

  /// Optional leading widget, takes precedence over [iconAsset].
  final Widget? icon;

  final bool isLoading;
  final bool isEnabled;

  /// When true the button fills the available width (the default in every
  /// design); set to false inside a `Row` that already sizes it.
  final bool expanded;

  final double height;
  final double radius;

  bool get _isInteractive => isEnabled && !isLoading && onPressed != null;

  Color get _fill => switch (variant) {
    AppButtonVariant.primary => AppColors.actionFill,
    AppButtonVariant.dark => AppColors.socialFill,
    AppButtonVariant.neutral => AppColors.denyFill,
    AppButtonVariant.outlined => AppColors.transparent,
  };

  Color get _ink => switch (variant) {
    AppButtonVariant.primary => AppColors.actionLabel,
    AppButtonVariant.dark => AppColors.actionLabel,
    AppButtonVariant.neutral => AppColors.denyLabel,
    AppButtonVariant.outlined => AppColors.authInk,
  };

  @override
  Widget build(BuildContext context) {
    final button = Opacity(
      opacity: isEnabled ? 1 : 0.5,
      child: Material(
        color: _fill,
        borderRadius: BorderRadius.circular(radius.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _isInteractive ? onPressed : null,
          child: Container(
            height: height.h,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.base.w + 2.w,
              vertical: AppSpacing.xs.h + 2.h,
            ),
            decoration: variant == AppButtonVariant.outlined
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(radius.r),
                    border: Border.all(
                      color: AppColors.fieldBorder,
                      width: AppSizes.borderWidth,
                    ),
                  )
                : null,
            alignment: Alignment.center,
            child: isLoading ? _Spinner(color: _ink) : _content(),
          ),
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _content() {
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.buttonLarge.rc(_ink),
    );

    final leading =
        icon ??
        (iconAsset != null
            ? Image.asset(
                iconAsset!,
                width: AppSizes.buttonIcon.w,
                height: AppSizes.buttonIcon.w,
                fit: BoxFit.contain,
              )
            : null);

    if (leading == null) return text;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [leading, AppSpacing.gapH(AppSpacing.xs + 2), Flexible(child: text)],
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.xl.w,
      height: AppSizes.xl.w,
      child: CircularProgressIndicator(
        strokeWidth: 2.2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
