import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../domain/entities/cash_payment.dart';
import 'payment_point_visuals.dart';

/// Availability pill — green when open, neutral grey when closed.
class OpenBadge extends StatelessWidget {
  const OpenBadge({super.key, required this.isOpen, this.label});

  final bool isOpen;

  /// Defaults to "Open" / "Closed"; the featured card passes "Open Now".
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs.w,
        vertical: AppSpacing.xxs.h + 1,
      ),
      decoration: BoxDecoration(
        color: isOpen ? AppColors.openSurface : AppColors.closedSurface,
        borderRadius: AppRadius.rFull,
      ),
      child: Text(
        label ??
            (isOpen ? AppStrings.openLabel.tr : AppStrings.closedLabel.tr),
        style: AppTextStyles.labelMedium.rc(
          isOpen ? AppColors.openInk : AppColors.closedInk,
        ),
      ),
    );
  }
}

/// A row in "ALL NEARBY": icon, name with availability, distance and hours,
/// and a Go action. The selected row carries a primary outline.
class PaymentPointTile extends StatelessWidget {
  const PaymentPointTile({
    super.key,
    required this.point,
    required this.isSelected,
    required this.onTap,
    required this.onGo,
  });

  final PaymentPoint point;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onGo;

  static const double _badge = 40;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      hasShadow: false,
      borderColor: isSelected ? AppColors.actionFill : AppColors.surfaceBorder,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm.w,
        vertical: AppSpacing.sm.h,
      ),
      child: Row(
        children: [
          Container(
            width: _badge.w,
            height: _badge.w,
            decoration: BoxDecoration(
              color: AppColors.accentSurface,
              borderRadius: AppRadius.rXl,
            ),
            alignment: Alignment.center,
            child: Icon(
              iconForPaymentPoint(point.kind),
              size: AppSizes.xl.w,
              color: AppColors.gray900,
            ),
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        point.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall.rc(AppColors.black),
                      ),
                    ),
                    AppSpacing.gapH(AppSpacing.xs),
                    OpenBadge(isOpen: point.isOpen),
                  ],
                ),
                AppSpacing.gapV(AppSpacing.xs2),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: AppSizes.base.w,
                      color: AppColors.gray400,
                    ),
                    AppSpacing.gapH(AppSpacing.xxs),
                    Flexible(
                      child: Text(
                        '${point.distanceLabel}  ${point.hoursLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.rc(AppColors.gray400),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          _GoButton(onTap: onGo),
        ],
      ),
    );
  }
}

class _GoButton extends StatelessWidget {
  const _GoButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.rFull,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.rFull,
            border: Border.all(
              color: AppColors.surfaceBorder,
              width: AppSizes.borderWidth,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm.w,
              vertical: AppSpacing.xs.h,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.near_me_outlined,
                  size: AppSizes.lg.w,
                  color: AppColors.gray900,
                ),
                AppSpacing.gapH(AppSpacing.xs2),
                Text(
                  AppStrings.go.tr,
                  style: AppTextStyles.titleSmall.rc(AppColors.gray900),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
