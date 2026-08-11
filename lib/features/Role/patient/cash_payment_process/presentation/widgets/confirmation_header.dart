import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';

/// Celebration emoji, green tick, headline and supporting line.
class ConfirmationHeader extends StatelessWidget {
  const ConfirmationHeader({super.key});

  static const List<String> _emoji = ['🎉', '✨', '🎊', '💊', '⭐'];
  static const double _badge = 96;
  static const double _emojiSize = 24;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final glyph in _emoji)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs.w),
                child: Text(glyph, style: TextStyle(fontSize: _emojiSize.sp)),
              ),
          ],
        ),
        AppSpacing.gapV(AppSpacing.md),
        Container(
          width: _badge.w,
          height: _badge.w,
          decoration: const BoxDecoration(
            color: AppColors.success600,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.check_rounded,
            size: (_badge * 0.5).w,
            color: AppColors.white,
          ),
        ),
        AppSpacing.gapV(AppSpacing.md),
        Text(
          AppStrings.paymentConfirmed.tr,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMedium.rc(AppColors.black),
        ),
        AppSpacing.gapV(AppSpacing.xs),
        Text(
          AppStrings.paymentConfirmedBody.tr,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
        ),
      ],
    );
  }
}
