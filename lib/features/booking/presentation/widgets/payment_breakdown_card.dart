import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/payment_method.dart';

/// Consultation fee, VAT and the total, ruled off above the total row.
class PaymentBreakdownCard extends StatelessWidget {
  const PaymentBreakdownCard({super.key, required this.breakdown});

  final PaymentBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.base.w),
      child: Column(
        children: [
          _Row(
            label: AppStrings.consultationFee.tr,
            value: breakdown.consultationFeeLabel,
          ),
          AppSpacing.gapV(AppSpacing.xs),
          _Row(label: AppStrings.vat.tr, value: breakdown.vatLabel),
          AppSpacing.gapV(AppSpacing.sm),
          Divider(
            height: AppSizes.borderWidth,
            thickness: AppSizes.borderWidth,
            color: AppColors.surfaceBorder,
          ),
          AppSpacing.gapV(AppSpacing.sm),
          _Row(
            label: AppStrings.totalPayable.tr,
            value: breakdown.totalLabel,
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyLarge.rc(AppColors.gray800),
        ),
        Text(
          value,
          style: isTotal
              ? AppTextStyles.titleMedium.rc(AppColors.primary500)
              : AppTextStyles.bodyLarge.rc(AppColors.black),
        ),
      ],
    );
  }
}
