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

/// The black card carrying the payment code.
///
/// Two layouts from one widget: the tall version on "How it works" (caption,
/// code, hint and a Copy Code pill) and the compact version on "Payment
/// Pending" (code with a square copy button on the right).
class PaymentCodeCard extends StatelessWidget {
  const PaymentCodeCard({
    super.key,
    required this.code,
    required this.onCopy,
    this.justCopied = false,
  }) : isCompact = false;

  /// Pending-screen variant: single row, square copy action.
  const PaymentCodeCard.compact({
    super.key,
    required this.code,
    required this.onCopy,
    this.justCopied = false,
  }) : isCompact = true;

  final String code;
  final VoidCallback onCopy;

  /// Swaps the copy affordance for a confirmation check.
  final bool justCopied;

  final bool isCompact;

  static const double _codeSize = 34;
  static const double _action = 48;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl2.r),
      child: ColoredBox(
        color: AppColors.codeSurface,
        child: Stack(
          children: [
            // Decorative disc bleeding off the top-right corner.
            Positioned(
              top: -60.h,
              right: -70.w,
              child: Container(
                width: 200.w,
                height: 200.w,
                decoration: const BoxDecoration(
                  color: AppColors.codeSurfaceAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.base.w),
              child: isCompact ? _compactBody() : _fullBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fullBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.paymentCode.tr,
          style: AppTextStyles.labelLarge
              .rc(AppColors.gray500)
              .copyWith(letterSpacing: 1.2),
        ),
        AppSpacing.gapV(AppSpacing.xs),
        _CodeText(code: code),
        AppSpacing.gapV(AppSpacing.xs),
        Text(
          AppStrings.useCodeAtAgent.tr,
          style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
        ),
        AppSpacing.gapV(AppSpacing.base),
        _CopyPill(onTap: onCopy, justCopied: justCopied),
      ],
    );
  }

  Widget _compactBody() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.paymentCode.tr,
                style: AppTextStyles.labelMedium
                    .rc(AppColors.gray500)
                    .copyWith(letterSpacing: 1.2),
              ),
              AppSpacing.gapV(AppSpacing.xs2),
              _CodeText(code: code),
            ],
          ),
        ),
        AppSpacing.gapH(AppSpacing.sm),
        _CopySquare(onTap: onCopy, justCopied: justCopied),
      ],
    );
  }
}

class _CodeText extends StatelessWidget {
  const _CodeText({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        code,
        maxLines: 1,
        style: AppTextStyles.headlineLarge
            .rc(AppColors.codeInk)
            .copyWith(
              fontSize: PaymentCodeCard._codeSize.sp,
              letterSpacing: 1.5,
            ),
      ),
    );
  }
}

class _CopyPill extends StatelessWidget {
  const _CopyPill({required this.onTap, required this.justCopied});

  final VoidCallback onTap;
  final bool justCopied;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: justCopied ? AppColors.openInk : AppColors.codeInk,
        borderRadius: AppRadius.rFull,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.base.w,
              vertical: AppSpacing.sm.h,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  justCopied ? Icons.check_rounded : Icons.copy_rounded,
                  size: AppSizes.xl.w,
                  color: justCopied ? AppColors.white : AppColors.gray900,
                ),
                AppSpacing.gapH(AppSpacing.xs),
                Text(
                  AppStrings.copyCode.tr,
                  style: AppTextStyles.titleSmall.rc(
                    justCopied ? AppColors.white : AppColors.gray900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CopySquare extends StatelessWidget {
  const _CopySquare({required this.onTap, required this.justCopied});

  final VoidCallback onTap;
  final bool justCopied;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: justCopied ? AppColors.openInk : AppColors.primary500,
      borderRadius: AppRadius.rXl,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: PaymentCodeCard._action.w,
          height: PaymentCodeCard._action.w,
          child: Icon(
            justCopied ? Icons.check_rounded : Icons.copy_rounded,
            size: AppSizes.xl2.w,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
