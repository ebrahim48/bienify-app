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
import 'payment_point_tile.dart';
import 'payment_point_visuals.dart';

/// The highlighted point directly under the map: name, hours, distance and
/// availability, with a black Directions action.
class FeaturedPaymentPointCard extends StatelessWidget {
  const FeaturedPaymentPointCard({
    super.key,
    required this.point,
    required this.onDirections,
  });

  final PaymentPoint point;
  final VoidCallback onDirections;

  static const double _badge = 44;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      borderColor: AppColors.actionFill,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(
                  point.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.rc(AppColors.black),
                ),
                AppSpacing.gapV(AppSpacing.xxs),
                Text(
                  point.hoursLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.rc(AppColors.gray400),
                ),
                AppSpacing.gapV(AppSpacing.xs),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        point.distanceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall.rc(
                          AppColors.actionFill,
                        ),
                      ),
                    ),
                    AppSpacing.gapH(AppSpacing.xs),
                    OpenBadge(
                      isOpen: point.isOpen,
                      label: point.isOpen ? AppStrings.openNow.tr : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          _DirectionsButton(onTap: onDirections),
        ],
      ),
    );
  }
}

class _DirectionsButton extends StatelessWidget {
  const _DirectionsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.codeSurface,
      borderRadius: AppRadius.rFull,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm.w,
            vertical: AppSpacing.xs.h + 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.near_me_outlined,
                size: AppSizes.lg.w,
                color: AppColors.white,
              ),
              AppSpacing.gapH(AppSpacing.xs2),
              Text(
                AppStrings.directions.tr,
                style: AppTextStyles.titleSmall.rc(AppColors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
