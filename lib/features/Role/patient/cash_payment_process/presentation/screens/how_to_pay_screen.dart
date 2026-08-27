import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../../data/static/cash_payment_data.dart';
import '../controllers/cash_payment_controller.dart';
import '../widgets/payment_code_card.dart';
import '../widgets/payment_info_row.dart';
import '../widgets/payment_steps_card.dart';

/// Step 1 of paying in cash: what will happen, the code, and how long it
/// lasts.
class HowToPayScreen extends GetView<CashPaymentController> {
  const HowToPayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.howToPaymentWorks.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.xs),
          PaymentStepsCard(steps: CashPaymentData.steps),
          AppSpacing.gapV(AppSpacing.md),
          Text(
            AppStrings.yourPaymentCode.tr,
            style: AppTextStyles.labelLarge
                .rc(AppColors.gray400)
                .copyWith(letterSpacing: 1.2),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          // Nothing shown until the server has issued one. A placeholder
          // stood here, and a payment code is a reference a patient reads off
          // the screen and quotes at a counter.
          Obx(() {
            final code = controller.code;
            if (code == null) return const SizedBox.shrink();
            return PaymentCodeCard(
              code: code.code,
              justCopied: controller.justCopied.value,
              onCopy: controller.copyCode,
            );
          }),
          AppSpacing.gapV(AppSpacing.xs),
          Obx(
            () => PaymentInfoRow(
              icon: Icons.timer_outlined,
              title: AppStrings.validForHours.trParams({
                'hours': '${(controller.code?.validFor ?? 0)}',
              }),
              subtitle: AppStrings.codeExpiresAfter.tr,
              value: controller.countdownLabel,
              valueCaption: AppStrings.remaining.tr,
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          PaymentInfoRow(
            icon: Icons.attach_money_rounded,
            title: AppStrings.amountToPay.tr,
            subtitle: (controller.code?.itemsLabel ?? ''),
            value: (controller.code?.amountLabel ?? ''),
            background: AppColors.accentSurface,
            showIconSurface: false,
            iconColor: AppColors.primary600,
          ),
          AppSpacing.gapV(AppSpacing.xl2),
          AppButton(
            label: AppStrings.findPaymentLocation.tr,
            icon: Icon(
              Icons.near_me_outlined,
              size: AppSizes.xl2.w,
              color: AppColors.actionLabel,
            ),
            onPressed: controller.findPaymentLocation,
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}
