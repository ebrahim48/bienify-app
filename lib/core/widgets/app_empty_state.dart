import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import 'app_button.dart';

/// Centred "nothing here yet" block: an illustration or glyph, a title, an
/// optional line of explanation and an optional action.
///
/// ```dart
/// AppEmptyState(
///   illustration: AppAssets.noPaymentMethod,
///   title: AppStrings.noPaymentMethod.tr,
///   body: AppStrings.noPaymentMethodBody.tr,
///   actionLabel: AppStrings.addPaymentMethod.tr,
///   onAction: controller.addPaymentMethod,
/// )
/// ```
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.body,
    this.illustration,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? body;

  /// Bundled artwork; takes precedence over [icon].
  final String? illustration;

  final IconData? icon;

  final String? actionLabel;
  final VoidCallback? onAction;

  static const double _illustration = 148;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl2.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (illustration != null)
            // Rounded and white-filled: the bundled artwork has its own light
            // background, so an unframed square edge would read as a stray
            // rectangle against the warm page colour.
            ClipRRect(
              borderRadius: AppRadius.rXl,
              child: Container(
                color: AppColors.white,
                width: _illustration.w,
                height: _illustration.w,
                child: Image.asset(illustration!, fit: BoxFit.contain),
              ),
            )
          else if (icon != null)
            Icon(icon, size: AppSizes.xl5.w, color: AppColors.gray300),
          AppSpacing.gapV(AppSpacing.base),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium.rc(AppColors.gray900),
          ),
          if (body != null) ...[
            AppSpacing.gapV(AppSpacing.xs2),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.rc(AppColors.gray400),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            AppSpacing.gapV(AppSpacing.md),
            AppButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}
