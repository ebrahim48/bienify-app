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
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../../../core/widgets/blurred_dialog.dart';
import '../../../doctor_role/domain/entities/doctor_practice.dart'
    show PayoutAccount;
import '../controllers/rider_profile_controller.dart';
import 'rider_add_payout_account_dialog.dart';

/// "Request Payout" for the courier.
///
/// The Earnings tab drew a bar toward the platform minimum and offered no way
/// to act on it, though `POST /wallet/withdrawals` has existed since the
/// wallet was built and the doctor's screens already used it. A courier could
/// watch money accumulate and never ask for any of it.
///
/// Bound to the courier's own controller rather than reusing the doctor's
/// dialog, which is a `GetView<EarningsController>` and reads that role's
/// state. The shared pieces — the card, the field, the buttons, the strings —
/// are the ones both use.
class RiderPayoutDialog extends StatefulWidget {
  const RiderPayoutDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showBlurredDialog<void>(
      context: context,
      builder: (_) => const RiderPayoutDialog(),
    );
  }

  @override
  State<RiderPayoutDialog> createState() => _RiderPayoutDialogState();
}

class _RiderPayoutDialogState extends State<RiderPayoutDialog> {
  final RiderProfileController _controller = Get.find<RiderProfileController>();

  /// Typed by the courier. Held here rather than on the controller so closing
  /// the dialog forgets it — a half-typed amount must not be waiting the next
  /// time it opens.
  String _amount = '';

  /// Which account the payout goes to. Starts on the courier's default.
  String? _accountId;

  /// The account list is taller than a small screen, so it scrolls inside the
  /// card rather than pushing the buttons off.
  static const double _maxListHeight = 300;

  /// Opens the form that files somewhere to be paid.
  ///
  /// The empty state used to be terminal: it said "Add a payout account first"
  /// and the rider role had no form to add one, so a courier with a balance
  /// could not withdraw it at all.
  Future<void> _addAccount() async {
    if (!await RiderAddPayoutAccountDialog.show(context)) return;
    if (!mounted) return;
    // Select what was just added, so the courier does not have to pick it.
    setState(() => _accountId = _controller.defaultPayoutAccount?.id);
  }

  @override
  void initState() {
    super.initState();
    _accountId = _controller.defaultPayoutAccount?.id;
  }

  Future<void> _submit() async {
    final earnings = _controller.earnings.value;
    final amount = double.tryParse(_amount.trim());

    if (amount == null || amount <= 0) {
      AppSnackbar.info(AppStrings.enterAValidAmount.tr);
      return;
    }
    // Checked here as well as on the server so the courier is told before a
    // round trip — but the server stays the authority, and its refusal is what
    // is shown if these disagree.
    if (amount < earnings.payoutMinimum) {
      AppSnackbar.info(
        AppStrings.belowMinimumPayout.trParams({
          'amount': earnings.minimumLabel,
        }),
      );
      return;
    }
    if (amount > earnings.withdrawable) {
      AppSnackbar.info(
        AppStrings.payoutPending.trParams({
          'amount': earnings.pendingWithdrawalLabel,
        }),
      );
      return;
    }

    final account = _accountId;
    if (account == null) {
      // Same distinction the list above draws: telling a courier to add an
      // account they may already have is worse than saying the list could not
      // be read.
      AppSnackbar.info(
        _controller.payoutAccountsError.value == null
            ? AppStrings.noPayoutAccount.tr
            : AppStrings.payoutAccountsUnreadable.tr,
      );
      return;
    }

    if (await _controller.requestPayout(amount, account) && mounted) {
      Navigator.of(context).pop();
    }
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
            AppStrings.requestPayout.tr,
            style: AppTextStyles.titleLarge.rw(
              AppColors.gray900,
              FontWeight.w400,
            ),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Text(
            AppStrings.availableToWithdraw.tr,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
          ),
          Obx(() {
            final earnings = _controller.earnings.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  earnings.withdrawableLabel,
                  style: AppTextStyles.headlineSmall.rc(AppColors.gray900),
                ),
                // Money already asked for is not offerable twice, and a
                // courier reading only a balance would think it was.
                if (earnings.pendingWithdrawal > 0) ...[
                  Text(
                    AppStrings.payoutPending.trParams({
                      'amount': earnings.pendingWithdrawalLabel,
                    }),
                    style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
                  ),
                  // Says what "available to withdraw" above does not: the
                  // figure went down because that money is spoken for, not
                  // because it was taken. The server does not touch the
                  // balance when a request is filed — it is debited only when
                  // an admin marks the withdrawal paid — but the courier can
                  // only see the smaller number, and reasonably read it as
                  // their money having already left.
                  Text(
                    AppStrings.payoutHeldNotDeducted.trParams({
                      'amount': earnings.availableLabel,
                    }),
                    style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
                  ),
                ],
              ],
            );
          }),
          AppSpacing.gapV(AppSpacing.xs),
          AppTextField(
            hint: AppStrings.amountToWithdraw.tr,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) => _amount = value,
          ),
          AppSpacing.gapV(AppSpacing.base),
          Text(
            AppStrings.payoutTo.tr,
            style: AppTextStyles.titleMedium.rw(
              AppColors.gray900,
              FontWeight.w400,
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: _maxListHeight.h),
            child: SingleChildScrollView(
              child: Obx(() {
                final accounts = _controller.payoutAccounts.toList();
                // A read that failed is not an empty list. Saying "add one
                // first" when the app could not find out whether there is one
                // sends a courier who already has an account to a form they
                // do not need — and the same failure would stop that form
                // saving anyway.
                final failure = _controller.payoutAccountsError.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (accounts.isEmpty && failure != null) ...[
                      Text(
                        AppStrings.payoutAccountsUnreadable.tr,
                        style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
                      ),
                      Text(
                        failure,
                        style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
                      ),
                      AppSpacing.gapV(AppSpacing.xs),
                    ] else if (accounts.isEmpty) ...[
                      Text(
                        AppStrings.noPayoutAccount.tr,
                        style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
                      ),
                      // Why a saved card does not count as one. Without this
                      // a courier who had added a debit card read the line
                      // above as the app losing it.
                      Text(
                        AppStrings.payoutNotCards.tr,
                        style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
                      ),
                      AppSpacing.gapV(AppSpacing.xs),
                    ],
                    for (final account in accounts) ...[
                      _AccountTile(
                        account: account,
                        isSelected: account.id == _accountId,
                        onTap: () => setState(() => _accountId = account.id),
                      ),
                      AppSpacing.gapV(AppSpacing.xs),
                    ],
                  ],
                );
              }),
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          AppButton(
            label: AppStrings.addPayoutAccount.tr,
            variant: AppButtonVariant.outlined,
            radius: AppRadius.lg,
            onPressed: _addAccount,
          ),
          AppSpacing.gapV(AppSpacing.base),
          // Unequal on purpose: "Request Payout" is twice the label "Cancel"
          // is, and at even widths it clips.
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
                child: Obx(
                  () => AppButton(
                    label: AppStrings.requestPayout.tr,
                    radius: AppRadius.lg,
                    isEnabled: !_controller.isRequestingPayout.value,
                    onPressed: _submit,
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

/// One destination the courier can be paid into.
class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.isSelected,
    required this.onTap,
  });

  final PayoutAccount account;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      hasShadow: false,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.base.w,
        vertical: AppSpacing.xs.h,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              account.label,
              style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
            ),
          ),
          Icon(
            isSelected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            color: isSelected ? AppColors.actionFill : AppColors.gray400,
          ),
        ],
      ),
    );
  }
}
