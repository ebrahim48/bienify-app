import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';

/// Onboarding page dots — the active page stretches into an 18×8 pill while
/// the rest stay 8×8 circles.
class AppPageIndicator extends StatelessWidget {
  const AppPageIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
    this.activeColor = AppColors.authInk,
    this.inactiveColor = AppColors.indicatorInactive,
    this.onDotTap,
  });

  final int count;
  final int currentIndex;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<int>? onDotTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++) ...[
          if (index > 0) SizedBox(width: AppSizes.dotGap.w),
          GestureDetector(
            onTap: onDotTap == null ? null : () => onDotTap!(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: (index == currentIndex
                  ? AppSizes.dotActiveWidth
                  : AppSizes.dotSize).w,
              height: AppSizes.dotSize.h,
              decoration: BoxDecoration(
                color: index == currentIndex ? activeColor : inactiveColor,
                borderRadius: AppRadius.rFull,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
