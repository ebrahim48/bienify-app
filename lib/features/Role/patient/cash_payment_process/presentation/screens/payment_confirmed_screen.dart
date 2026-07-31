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
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../controllers/payment_confirmed_controller.dart';
import '../widgets/booking_details_card.dart';
import '../widgets/confirmation_header.dart';

/// Final step: the agent has taken the cash and the booking is confirmed.
///
/// No back bar — the flow is finished, so the only way on is Go Home.
class PaymentConfirmedScreen extends GetView<PaymentConfirmedController> {
  const PaymentConfirmedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.md),
          const ConfirmationHeader(),
          AppSpacing.gapV(AppSpacing.md),
          BookingDetailsCard(confirmation: controller.confirmation),
          AppSpacing.gapV(AppSpacing.sm),
          _PaidViaStrip(code: controller.confirmation.paidViaLabel),
          AppSpacing.gapV(AppSpacing.base),
          AppButton(
            label: AppStrings.goHome.tr,
            icon: Icon(
              Icons.home_outlined,
              size: AppSizes.xl2.w,
              color: AppColors.actionLabel,
            ),
            onPressed: controller.goHome,
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

/// The tinted footnote naming how the order was settled.
class _PaidViaStrip extends StatelessWidget {
  const _PaidViaStrip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm.w,
        vertical: AppSpacing.sm.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: AppRadius.rXl,
      ),
      child: Row(
        children: [
          Icon(
            Icons.payments_outlined,
            size: AppSizes.xl.w,
            color: AppColors.primary700,
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Expanded(
            child: Text(
              AppStrings.paidViaCash.trParams({'code': code}),
              maxLines: 2,
              style: AppTextStyles.labelLarge.rc(AppColors.gray900),
            ),
          ),
        ],
      ),
    );
  }
}
