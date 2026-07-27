import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

/// The `‹ Title` header shared by every inner auth screen.
///
/// A plain widget rather than an `AppBar` so it participates in the page's
/// scroll view and keeps the exact 56pt height / 24pt chevron inset measured
/// from the designs.
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.showBack = true,
    this.trailing,
  });

  final String title;

  /// Defaults to popping the current route.
  final VoidCallback? onBack;

  final bool showBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.appBarHeight.h,
      child: Row(
        children: [
          if (showBack)
            _BackButton(onTap: onBack ?? () => Get.back<void>())
          else
            AppSpacing.gapH(AppSpacing.xs),
          AppSpacing.gapH(AppSpacing.xs2),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleMedium.rc(AppColors.authInk),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: AppSizes.xl2.r,
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xs.w),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: AppSizes.xl.w,
          color: AppColors.authInk,
        ),
      ),
    );
  }
}
