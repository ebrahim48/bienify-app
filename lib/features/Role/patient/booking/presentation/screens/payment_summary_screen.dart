import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
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
