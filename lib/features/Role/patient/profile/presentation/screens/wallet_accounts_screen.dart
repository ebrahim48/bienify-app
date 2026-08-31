import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_icons.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/app_empty_state.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../controllers/account_controller.dart';

/// Wallet — the accounts added to it, and the way to add another.
class WalletAccountsScreen extends GetView<AccountController> {
  const WalletAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.walletTitle.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          // Both lists are read here so either repaints when it changes.
          Obx(() {
            final cards = controller.cards.toList();
            final payouts = controller.payoutAccounts.toList();
            if (cards.isEmpty && payouts.isEmpty) {
              return AppEmptyState(
                icon: Icons.credit_card_off_outlined,
                title: AppStrings.noPaymentMethod.tr,
                body: AppStrings.noPaymentMethodBody.tr,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The distinction, said once at the top. A courier who saved
                // two debit cards here and then read "Add a payout account
                // first" on the payout sheet reasonably concluded the app had
                // lost them: cards are how money comes *in*, and a payout goes
                // *out* to a bank or mobile-money account the server keeps in
                // an entirely separate list. Both now appear on this screen,
                // under headings that say which is which.
                Text(
                  AppStrings.cardsPayNotReceive.tr,
                  style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
                ),
                AppSpacing.gapV(AppSpacing.xs),
                // Payout accounts first: this screen is reached from Earnings
                // as often as from checkout, and the courier asking "where did
                // my account go" is looking for this list.
                if (payouts.isNotEmpty) ...[
                  _SectionHeading(AppStrings.payoutAccountsHeading.tr),
                  for (final account in payouts) ...[
                    AppCard(
                      hasShadow: false,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.base.w,
                        vertical: AppSpacing.sm.h,
                      ),
                      child: Row(
                        children: [
                          AppSvgIcon(
                            AppIcons.wallet,
                            size: AppSizes.xl2,
                            color: AppColors.actionFill,
                          ),
                          AppSpacing.gapH(AppSpacing.sm),
                          Expanded(
                            child: Text(
                              account.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleMedium.rw(
                                AppColors.gray900,
                                FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapV(AppSpacing.sm),
                  ],
                ],
                if (cards.isNotEmpty)
                  _SectionHeading(AppStrings.cardsHeading.tr),
                for (final card in cards) ...[
                  AppCard(
                    hasShadow: false,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.base.w,
                      vertical: AppSpacing.sm.h,
                    ),
                    child: Row(
                      children: [
                        AppSvgIcon(
                          AppIcons.wallet,
                          size: AppSizes.xl2,
                          color: AppColors.actionFill,
                        ),
                        AppSpacing.gapH(AppSpacing.sm),
                        Expanded(
                          child: Text(
                            card.brand,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleMedium.rw(
                              AppColors.gray900,
                              FontWeight.w400,
                            ),
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => controller.removeCard(card),
                          child: AppSvgIcon(
                            AppIcons.delete,
                            size: AppSizes.xl2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapV(AppSpacing.sm),
                ],
              ],
            );
          }),
          AppSpacing.gapV(AppSpacing.xs2),
          _AddAccountButton(onTap: controller.openPaymentOptions),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

/// Names which of the two lists follows.
///
/// Shown only when there is something under it, so a wallet with cards and no
/// payout account does not print an empty "Paid out to".
class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs2.h),
      child: Text(
        label,
        style: AppTextStyles.bodyLarge.rw(AppColors.gray900, FontWeight.w500),
      ),
    );
  }
}

/// Sized to its label and left-aligned, as the design places it under the
/// list rather than across the page.
class _AddAccountButton extends StatelessWidget {
  const _AddAccountButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: AppColors.actionFill,
        borderRadius: AppRadius.rLg,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm.w,
              vertical: AppSpacing.xs.h,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: AppSizes.xl.w,
                  color: AppColors.actionLabel,
                ),
                AppSpacing.gapH(AppSpacing.xs2),
                Text(
                  AppStrings.addAccount.tr,
                  style: AppTextStyles.bodyLarge.rc(AppColors.actionLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
