import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_card.dart';

/// Icon + title/subtitle on the left, a value (with optional caption) on the
/// right.
///
/// Covers the "Valid for 24 hours", "Amount to pay" and "Time remaining"
/// rows, which differ only in fill and emphasis.
class PaymentInfoRow extends StatelessWidget {
  const PaymentInfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.valueCaption,
    this.background = AppColors.surface,
    this.iconColor = AppColors.primary600,
    this.iconBackground = AppColors.accentSurface,
    this.showIconSurface = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final String? valueCaption;

  final Color background;
  final Color iconColor;
  final Color iconBackground;

  /// False draws a bare glyph, as the "Time remaining" row does.
  final bool showIconSurface;

  static const double _badge = 40;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: background,
      hasShadow: false,
      borderColor: background == AppColors.surface
          ? AppColors.surfaceBorder
          : background,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm.w,
        vertical: AppSpacing.sm.h,
      ),
      child: Row(
        children: [
          if (showIconSurface)
            Container(
              width: _badge.w,
              height: _badge.w,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: AppRadius.rXl,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: AppSizes.xl.w, color: iconColor),
            )
          else
            SizedBox(
              width: _badge.w,
              child: Icon(icon, size: AppSizes.xl2.w, color: iconColor),
            ),
          AppSpacing.gapH(AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.rc(AppColors.black),
                ),
                AppSpacing.gapV(AppSpacing.xxs),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium.rc(AppColors.gray400),
                ),
              ],
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: AppTextStyles.headlineSmall.rc(AppColors.black),
              ),
              if (valueCaption != null)
                Text(
                  valueCaption!,
                  style: AppTextStyles.bodySmall.rc(AppColors.gray400),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
