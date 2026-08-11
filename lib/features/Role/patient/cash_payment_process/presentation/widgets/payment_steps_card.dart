import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../domain/entities/cash_payment.dart';

/// The numbered "how it works" list, with a connector running between the
/// step markers.
class PaymentStepsCard extends StatelessWidget {
  const PaymentStepsCard({super.key, required this.steps});

  final List<PaymentStep> steps;

  static const double _marker = 36;
  static const double _rowGap = 22;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: AppRadius.xl2,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.base.w,
        vertical: AppSpacing.md.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < steps.length; index++)
            _Step(
              index: index,
              step: steps[index],
              isLast: index == steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.index, required this.step, required this.isLast});

  final int index;
  final PaymentStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: PaymentStepsCard._marker.w,
                height: PaymentStepsCard._marker.w,
                decoration: const BoxDecoration(
                  color: AppColors.actionFill,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: AppTextStyles.titleSmall.rc(AppColors.white),
                ),
              ),
              // The connector stops at the last marker.
              if (!isLast)
                Expanded(
                  child: Container(
                    width: AppSizes.borderWidth,
                    color: AppColors.surfaceBorder,
                  ),
                ),
            ],
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : PaymentStepsCard._rowGap.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    step.title.tr,
                    style: AppTextStyles.titleSmall.rc(AppColors.black),
                  ),
                  AppSpacing.gapV(AppSpacing.xs2),
                  Text(
                    step.description.tr,
                    style: AppTextStyles.bodyMedium.rc(AppColors.gray400),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
