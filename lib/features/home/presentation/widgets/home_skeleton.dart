import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';

/// Shimmer placeholder shown while the feed loads.
///
/// Mirrors the real layout's block sizes so content does not jump when it
/// arrives.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.gray100,
      highlightColor: AppColors.gray50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Block(height: AppSizes.controlHeight, radius: AppRadius.xl),
          AppSpacing.gapV(AppSpacing.base),
          const _Block(height: 154),
          AppSpacing.gapV(AppSpacing.md),
          const _Block(height: AppSizes.xl2, width: 180),
          AppSpacing.gapV(AppSpacing.sm),
          const _Block(height: 113),
          AppSpacing.gapV(AppSpacing.md),
          const _Block(height: AppSizes.xl2, width: 140),
          AppSpacing.gapV(AppSpacing.sm),
          for (var i = 0; i < 4; i++) ...[
            const _Block(height: 68),
            AppSpacing.gapV(AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.height, this.width, this.radius = AppRadius.xl});

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: height.h,
        width: width?.w ?? double.infinity,
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(radius.r),
        ),
      ),
    );
  }
}
