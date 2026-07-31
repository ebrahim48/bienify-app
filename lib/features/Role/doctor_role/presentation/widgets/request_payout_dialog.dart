import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/blurred_dialog.dart';
import '../../../patient/booking/domain/entities/payment_method.dart';
import '../../../patient/booking/presentation/widgets/payment_method_tile.dart';
import '../controllers/earnings_controller.dart';

/// "Request Payout" over a blurred Earning Withdraw.
///
/// Reuses the booking flow's `PaymentMethodTile` and its method list, so the
/// six rows are not written a fourth time.
class RequestPayoutDialog extends GetView<EarningsController> {
  const RequestPayoutDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showBlurredDialog<void>(
      context: context,
      builder: (_) => const RequestPayoutDialog(),
    );
  }

  /// The method list is taller than the screen on a small device, so it
  /// scrolls inside the card rather than pushing the actions off.
  static const double _maxListHeight = 380;

  @override
  Widget build(BuildContext context) {
    return AppDialogCard(
      padding: EdgeInsets.all(AppSpacing.base.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.requestPayout.tr,
            style: AppTextStyles.titleLarge.rw(
              AppColors.gray900,
              FontWeight.w400,
            ),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Text(
            AppStrings.amountToWithdraw.tr,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
          ),
          Text(
            controller.availableBalance,
            style: AppTextStyles.headlineSmall.rc(AppColors.gray900),
          ),
          AppSpacing.gapV(AppSpacing.base),
          Text(
            AppStrings.selectPayoutMethod.tr,
            style: AppTextStyles.titleMedium.rw(
              AppColors.gray900,
              FontWeight.w400,
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: _maxListHeight.h),
            child: SingleChildScrollView(
              child: Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (
                      var index = 0;
                      index < PaymentMethod.values.length;
                      index++
                    ) ...[
                      PaymentMethodTile(
                        method: PaymentMethod.values[index],
                        isSelected:
                            index == controller.selectedMethodIndex.value,
                        onTap: () => controller.selectMethod(index),
                      ),
                      AppSpacing.gapV(AppSpacing.xs),
                    ],
                  ],
                ),
              ),
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          // Unequal on purpose: "Request Payout" is twice the label "Cancel"
          // is, and at even widths it clipped to "Request Payo…".
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AppButton(
                  label: AppStrings.cancel.tr,
                  variant: AppButtonVariant.outlined,
                  radius: AppRadius.lg,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              AppSpacing.gapH(AppSpacing.sm),
              Expanded(
                flex: 3,
                child: AppButton(
                  label: AppStrings.requestPayout.tr,
                  radius: AppRadius.lg,
                  onPressed: controller.requestPayout,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
