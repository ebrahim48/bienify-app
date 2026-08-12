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
import '../../../../../core/widgets/app_pill_selector.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../../../core/widgets/blurred_dialog.dart';
import '../controllers/earnings_controller.dart';

/// "Add payout Account", over the payout request it is opened from.
///
/// The wallet's Add Account leads to the card form, which files a way to *pay*
/// — a withdrawal needs a way to *be paid*, and nothing else in the app
/// created one, so Request Payout could never succeed.
class AddPayoutAccountDialog extends GetView<EarningsController> {
  const AddPayoutAccountDialog({super.key});

  /// Resolves to whether an account was filed, so the caller can decide
  /// whether to reopen the request behind it.
  static Future<bool> show(BuildContext context) async {
    final added = await showBlurredDialog<bool>(
      context: context,
      builder: (_) => const AddPayoutAccountDialog(),
    );
    return added ?? false;
  }

  /// The two the server accepts, in its own spelling.
  static const List<String> _kinds = ['bank', 'mobile_money'];

  @override
  Widget build(BuildContext context) {
    return AppDialogCard(
      padding: EdgeInsets.all(AppSpacing.base.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.addPayoutAccount.tr,
            style: AppTextStyles.titleLarge.rw(
              AppColors.gray900,
              FontWeight.w400,
            ),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Obx(
            () => AppPillSelector(
              labels: [
                AppStrings.payoutKindBank.tr,
                AppStrings.payoutKindMobileMoney.tr,
              ],
              selectedIndex: _kinds.indexOf(controller.accountKind.value),
              onSelected: (index) =>
                  controller.selectAccountKind(_kinds[index]),
            ),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          AppTextField(
            hint: AppStrings.payoutAccountName.tr,
            onChanged: controller.setAccountName,
          ),
          AppSpacing.gapV(AppSpacing.xs),
          AppTextField(
            hint: AppStrings.payoutAccountNumber.tr,
            keyboardType: TextInputType.number,
            onChanged: controller.setAccountNumber,
          ),
          AppSpacing.gapV(AppSpacing.xs),
          // Only a bank account has one, so it is optional rather than a
          // second required field on a mobile-money number.
          AppTextField(
            hint: AppStrings.payoutBankName.tr,
            onChanged: controller.setAccountBank,
          ),
          AppSpacing.gapV(AppSpacing.base),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: AppStrings.cancel.tr,
                  variant: AppButtonVariant.outlined,
                  radius: AppRadius.lg,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              AppSpacing.gapH(AppSpacing.sm),
              Expanded(
                child: Obx(
                  () => AppButton(
                    label: AppStrings.save.tr,
                    radius: AppRadius.lg,
                    isEnabled: !controller.isSavingAccount.value,
                    onPressed: () async {
                      final added = await controller.addPayoutAccount();
                      if (added && context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
