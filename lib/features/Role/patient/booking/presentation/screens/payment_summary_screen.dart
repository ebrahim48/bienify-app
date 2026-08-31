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
import '../../../appointments/presentation/widgets/appointment_card.dart';
import '../../domain/entities/payment_method.dart';
import '../controllers/payment_controller.dart';
import '../widgets/medical_document_picker.dart';
import '../widgets/payment_breakdown_card.dart';
import '../widgets/payment_method_tile.dart';
import '../widgets/wallet_card.dart';

/// Payment Summary: optional documents, the appointment being paid for, the
/// money breakdown, the wallet toggle, and the method list.
class PaymentSummaryScreen extends GetView<PaymentController> {
  const PaymentSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.paymentSummary.tr),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.gapV(AppSpacing.base),
            Text(
              AppStrings.medicalDocument.tr,
              style: AppTextStyles.titleSmall.rc(AppColors.authInk),
            ),
            AppSpacing.gapV(AppSpacing.xs),
            MedicalDocumentPicker(
              onAttach: controller.addAttachment,
              onCamera: controller.captureFromCamera,
              attachments: controller.attachments.toList(),
              onRemove: controller.removeAttachment,
            ),
            AppSpacing.gapV(AppSpacing.sm),
            AppointmentCard(
              appointment: controller.appointment,
              showJoin: false,
            ),
            AppSpacing.gapV(AppSpacing.sm),
            PaymentBreakdownCard(breakdown: controller.breakdown),
            AppSpacing.gapV(AppSpacing.sm),
            WalletCard(
              wallet: controller.wallet.value,
              // The whole bill, because that is what the server takes from the
              // balance — not the lesser of bill and balance, which would
              // under-promise when the wallet is short and the payment is
              // about to be refused for exactly that reason.
              deductionLabel: controller.breakdown.totalLabel,
              isEnabled: controller.useWallet.value,
              onChanged: controller.toggleWallet,
            ),
            // Shown only when the wallet cannot cover the bill, which is the
            // one moment a patient needs the top-up screen and the only place
            // they would think to look for it.
            if (controller.isWalletShort) ...[
              AppSpacing.gapV(AppSpacing.xs),
              _WalletShortNote(onTopUp: controller.topUp),
            ],
            AppSpacing.gapV(AppSpacing.base),
            Text(
              AppStrings.choosePaymentMethod.tr,
              style: AppTextStyles.titleLarge.rc(AppColors.black),
            ),
            AppSpacing.gapV(AppSpacing.xs),
            for (final method in PaymentMethod.values) ...[
              PaymentMethodTile(
                method: method,
                isSelected: controller.isSelected(method),
                onTap: () => controller.selectMethod(method),
              ),
              AppSpacing.gapV(AppSpacing.sm),
            ],
            AppSpacing.gapV(AppSpacing.base),
            AppButton(
              label: AppStrings.payAmount.trParams({
                'amount': controller.breakdown.payableLabel,
              }),
              isLoading: controller.isSubmitting.value,
              onPressed: controller.pay,
            ),
            AppSpacing.gapV(AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// Says the wallet is short and offers the one action that fixes it.
///
/// Without this the payment simply failed with "Insufficient wallet balance"
/// and the patient had nowhere to go — the wallet had no way to be filled.
class _WalletShortNote extends StatelessWidget {
  const _WalletShortNote({required this.onTopUp});

  final VoidCallback onTopUp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: AppSizes.lg.w,
          color: AppColors.gray400,
        ),
        AppSpacing.gapH(AppSpacing.xs2),
        Expanded(
          child: Text(
            AppStrings.walletShort.tr,
            style: AppTextStyles.bodyMedium.rc(AppColors.gray400),
          ),
        ),
        AppSpacing.gapH(AppSpacing.xs),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTopUp,
          child: Text(
            AppStrings.addMoney.tr,
            style: AppTextStyles.titleSmall.rc(AppColors.primary600),
          ),
        ),
      ],
    );
  }
}
