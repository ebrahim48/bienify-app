import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/payment_method.dart';

/// A selectable payment row: tinted icon, label, and a check bubble that
/// fills `primary500` when chosen.
class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({
    super.key,
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final PaymentMethod method;
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
              method.labelKey.tr,
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
