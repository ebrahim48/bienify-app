import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_icons.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../../../core/widgets/blurred_dialog.dart';
import '../../domain/entities/doctor_practice.dart';
import '../controllers/earnings_controller.dart';
import 'add_payout_account_dialog.dart';

/// "Request Payout" over a blurred Earning Withdraw.
///
/// Lists the practitioner's own payout accounts rather than the booking
/// flow's method catalogue: a withdrawal has to name an account the server
/// already holds, and "Tpago" as an abstract method is not one.
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
          Obx(
            () => Text(
              controller.availableBalance.value,
              style: AppTextStyles.headlineSmall.rc(AppColors.gray900),
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          AppTextField(
            hint: AppStrings.amountToWithdraw.tr,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: controller.setAmount,
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
              child: Obx(() {
                final accounts = controller.accounts.toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (accounts.isEmpty)
                      Text(
                        AppStrings.noPayoutAccount.tr,
                        style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
                      ),
                    for (var index = 0; index < accounts.length; index++) ...[
                      _AccountTile(
                        account: accounts[index],
                        isSelected:
                            index == controller.selectedMethodIndex.value,
                        onTap: () => controller.selectMethod(index),
                      ),
                      AppSpacing.gapV(AppSpacing.xs),
                    ],
                    AppSpacing.gapV(AppSpacing.xs),
                    // Without this the dialog is a dead end for a doctor who
                    // has never been paid: the wallet's Add Account files a
                    // card to pay with, not an account to be paid into.
                    AppButton(
                      label: AppStrings.addPayoutAccount.tr,
                      variant: AppButtonVariant.outlined,
                      radius: AppRadius.lg,
                      onPressed: () => AddPayoutAccountDialog.show(context),
                    ),
                  ],
                );
              }),
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
                child: Obx(
                  () => AppButton(
                    label: AppStrings.requestPayout.tr,
                    radius: AppRadius.lg,
                    isEnabled: !controller.isRequestingPayout.value,
                    onPressed: controller.requestPayout,
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

/// A selectable payout account: tinted icon, label, and a check bubble that
/// fills `primary500` when chosen — the booking flow's method row, over an
/// account the server holds rather than a catalogue entry.
class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.isSelected,
    required this.onTap,
  });

  final PayoutAccount account;
  final bool isSelected;
  final VoidCallback onTap;

  static const double _badge = 44;
  static const double _radio = 24;

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
          Container(
            width: _badge.w,
            height: _badge.w,
            decoration: const BoxDecoration(
              color: AppColors.accentSurface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: AppSvgIcon(
              AppIcons.wallet,
              size: AppSizes.xl2,
              color: AppColors.primary600,
            ),
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Text(
              account.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleSmall.rc(AppColors.black),
            ),
          ),
          Container(
            width: _radio.w,
            height: _radio.w,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary500 : AppColors.gray100,
              shape: BoxShape.circle,
            ),
            child: isSelected
                ? Icon(
                    Icons.check_rounded,
                    size: AppSizes.lg.w,
                    color: AppColors.white,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
