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
    this.subtitle,
    this.onBack,
    this.showBack = true,
    this.trailing,
  });

  final String title;

  /// A grey second line under the title — who the page is about, as the
  /// ordering flow labels every step ("Request lab Test" / "Amelia Hart").
  /// The bar grows to fit it; without one the height is unchanged.
  final String? subtitle;

  /// Defaults to popping the current route.
  final VoidCallback? onBack;

  final bool showBack;
  final Widget? trailing;

  /// Extra height the second line needs.
  static const double _subtitleHeight = 20;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: subtitle == null
          ? AppSizes.appBarHeight.h
          : (AppSizes.appBarHeight + _subtitleHeight).h,
      child: Row(
        children: [
          if (showBack)
            _BackButton(onTap: onBack ?? () => Get.back<void>())
          else
            AppSpacing.gapH(AppSpacing.xs),
          AppSpacing.gapH(AppSpacing.xs2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.rc(AppColors.authInk),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
                  ),
              ],
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
