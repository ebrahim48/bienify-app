import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_icons.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/payment_method.dart';

/// RxWallet row with its balance, the toggle, and the deduction note that
/// appears under a rule while the toggle is on.
class WalletCard extends StatelessWidget {
  const WalletCard({
    super.key,
    required this.wallet,
    required this.deductionLabel,
    required this.isEnabled,
    required this.onChanged,
  });

  final Wallet wallet;

  /// What will actually come out, which is the bill when the balance covers
  /// it. Printing the balance instead promised to take $879.01 towards a $50
  /// consultation — the same fault the pharmacy basket already fixed.
  final String deductionLabel;

  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  static const double _badge = 44;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.base.w),
      child: Column(
        children: [
          Row(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.rxWallet.tr,
                      style: AppTextStyles.titleSmall.rc(AppColors.black),
                    ),
                    Text(
                      AppStrings.walletBalance.trParams({
                        'amount': wallet.balanceLabel,
                      }),
                      style: AppTextStyles.bodyMedium.rc(AppColors.gray400),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isEnabled,
                onChanged: onChanged,
                activeThumbColor: AppColors.white,
                activeTrackColor: AppColors.actionFill,
                inactiveThumbColor: AppColors.white,
                inactiveTrackColor: AppColors.gray200,
                trackOutlineColor: WidgetStateProperty.all(
                  AppColors.transparent,
                ),
              ),
            ],
          ),
          if (isEnabled) ...[
            AppSpacing.gapV(AppSpacing.sm),
            Divider(
              height: AppSizes.borderWidth,
              thickness: AppSizes.borderWidth,
              color: AppColors.surfaceBorder,
            ),
            AppSpacing.gapV(AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppStrings.walletDeduction.trParams({
                  'amount': deductionLabel,
                }),
                style: AppTextStyles.labelLarge.rc(AppColors.gray800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
