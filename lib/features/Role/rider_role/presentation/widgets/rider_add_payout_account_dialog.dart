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
import '../controllers/rider_profile_controller.dart';

/// "Add payout Account" for the courier.
///
/// The rider role had no such form. `addPayoutAccount` existed on the
/// controller and the repository behind it, and nothing anywhere called it —
/// so `RiderPayoutDialog` told a courier to add a payout account and gave them
/// nowhere to do it. A courier who had saved a debit card in the wallet was
/// stuck: that files a way to *pay* (`/wallet/cards`), and a withdrawal is
/// paid *out* to a separate account (`/wallet/payout-accounts`), whose server
/// side accepts only a bank or a mobile money number.
///
/// Bound to the courier's own controller rather than reusing the doctor's
/// dialog, which is a `GetView<EarningsController>` and reads that role's
/// state — the same split `RiderPayoutDialog` already makes.
class RiderAddPayoutAccountDialog extends StatefulWidget {
  const RiderAddPayoutAccountDialog({super.key});

  /// Resolves to whether an account was filed, so the payout sheet behind it
  /// knows whether it now has somewhere to pay.
  static Future<bool> show(BuildContext context) async {
    final added = await showBlurredDialog<bool>(
      context: context,
      builder: (_) => const RiderAddPayoutAccountDialog(),
    );
    return added ?? false;
  }

  @override
  State<RiderAddPayoutAccountDialog> createState() =>
      _RiderAddPayoutAccountDialogState();
}

class _RiderAddPayoutAccountDialogState
    extends State<RiderAddPayoutAccountDialog> {
  final RiderProfileController _controller = Get.find<RiderProfileController>();

  /// The two the server accepts, in its own spelling — the `kind` enum on
  /// `PayoutAccount` is `bank | mobile_money` and nothing else.
  static const List<String> _kinds = ['bank', 'mobile_money'];

  /// Held here rather than on the controller so closing the dialog forgets a
  /// half-typed account, the same way the payout sheet forgets an amount.
  String _kind = _kinds.first;
  String _name = '';
  String _number = '';
  String _bank = '';

  Future<void> _save() async {
    final added = await _controller.addPayoutAccount(
      kind: _kind,
      displayName: _name,
      accountNumber: _number,
      bankName: _bank,
    );
    if (added && mounted) Navigator.of(context).pop(true);
  }

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
          AppSpacing.gapV(AppSpacing.xs),
          // Says why a saved card is not an answer here. A courier who had
          // added one reasonably read "add a payout account first" as the app
          // failing to see it.
          Text(
            AppStrings.payoutNotCards.tr,
            style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          AppPillSelector(
            labels: [
              AppStrings.payoutKindBank.tr,
              AppStrings.payoutKindMobileMoney.tr,
            ],
            selectedIndex: _kinds.indexOf(_kind),
            onSelected: (index) => setState(() => _kind = _kinds[index]),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          AppTextField(
            hint: AppStrings.payoutAccountName.tr,
            onChanged: (value) => _name = value,
          ),
          AppSpacing.gapV(AppSpacing.xs),
          AppTextField(
            hint: AppStrings.payoutAccountNumber.tr,
            keyboardType: TextInputType.number,
            onChanged: (value) => _number = value,
          ),
          AppSpacing.gapV(AppSpacing.xs),
          // Only a bank account has one, so it is optional rather than a
          // second required field on a mobile-money number.
          AppTextField(
            hint: AppStrings.payoutBankName.tr,
            onChanged: (value) => _bank = value,
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
                    isEnabled: !_controller.isSavingPayoutAccount.value,
                    onPressed: _save,
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
