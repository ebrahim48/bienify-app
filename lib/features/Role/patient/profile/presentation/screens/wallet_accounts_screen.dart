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
          // Cards are read here so the list repaints when one is removed.
          Obx(() {
            final cards = controller.cards.toList();
            if (cards.isEmpty) {
              return AppEmptyState(
                icon: Icons.credit_card_off_outlined,
                title: AppStrings.noPaymentMethod.tr,
                body: AppStrings.noPaymentMethodBody.tr,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
