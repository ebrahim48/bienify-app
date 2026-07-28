import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../controllers/cash_payment_controller.dart';
import '../widgets/code_copied_banner.dart';
import '../widgets/payment_code_card.dart';
import '../widgets/payment_info_row.dart';

/// Step 3: the code is issued and the app is waiting for the agent to
/// confirm.
class PaymentPendingScreen extends GetView<CashPaymentController> {
  const PaymentPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      padded: false,
      topBar: Padding(
        padding: AppSpacing.pagePadding,
        child: AppTopBar(title: AppStrings.paymentPending.tr),
      ),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Full-bleed, so it sits flush with the screen edges.
            CodeCopiedBanner(
              code: controller.code.code,
              isVisible: controller.justCopied.value,
            ),
            Padding(
              padding: AppSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSpacing.gapV(AppSpacing.base),
                  const _WaitingPanel(),
                  AppSpacing.gapV(AppSpacing.md),
                  PaymentCodeCard.compact(
                    code: controller.code.code,
                    justCopied: controller.justCopied.value,
                    onCopy: controller.copyCode,
                  ),
                  AppSpacing.gapV(AppSpacing.base),
                  PaymentInfoRow(
                    icon: Icons.timer_outlined,
                    title: AppStrings.timeRemaining.tr,
                    subtitle: AppStrings.codeValidFrom.trParams({
                      'hours': '${controller.code.validFor}',
                    }),
                    value: controller.countdownLabel,
                    iconColor: AppColors.timerAccent,
                    showIconSurface: false,
                  ),
                  AppSpacing.gapV(AppSpacing.sm),
                  const _AutoCheckingNote(),
                  AppSpacing.gapV(AppSpacing.base),
                  AppButton(
                    label: AppStrings.checkPaymentStatus.tr,
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: AppSizes.xl2.w,
                      color: AppColors.actionLabel,
                    ),
                    onPressed: controller.checkStatus,
                  ),
                  AppSpacing.gapV(AppSpacing.sm),
                  AppButton(
                    label: AppStrings.viewNearbyLocations.tr,
                    variant: AppButtonVariant.outlined,
                    icon: Icon(
                      Icons.near_me_outlined,
                      size: AppSizes.xl.w,
                      color: AppColors.authInk,
                    ),
                    onPressed: controller.viewNearbyLocations,
                  ),
                  AppSpacing.gapV(AppSpacing.md),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The tinted "Waiting for Payment" panel.
class _WaitingPanel extends StatelessWidget {
  const _WaitingPanel();

  static const double _icon = 72;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md.w,
        vertical: AppSpacing.lg.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.pendingSurface,
        borderRadius: AppRadius.rXl2,
      ),
      child: Column(
        children: [
          Container(
            width: _icon.w,
            height: _icon.w,
            decoration: const BoxDecoration(
              color: AppColors.pendingIconSurface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.timer_outlined,
              size: AppSizes.xl3.w,
              color: AppColors.gray900,
            ),
          ),
          AppSpacing.gapV(AppSpacing.md),
          Text(
            AppStrings.waitingForPayment.tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge.rc(AppColors.black),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          Text(
            AppStrings.waitingForPaymentBody.tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
          ),
        ],
      ),
    );
  }
}

class _AutoCheckingNote extends StatelessWidget {
  const _AutoCheckingNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.autorenew_rounded,
          size: AppSizes.lg.w,
          color: AppColors.gray400,
        ),
        AppSpacing.gapH(AppSpacing.xs),
        Text(
          AppStrings.autoChecking.trParams({
            'seconds': '${CashPaymentController.autoCheckSeconds}',
          }),
          style: AppTextStyles.bodyLarge.rc(AppColors.gray400),
        ),
      ],
    );
  }
}
