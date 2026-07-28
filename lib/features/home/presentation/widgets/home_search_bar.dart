import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';

/// The "Search Specialty" bar on Home.
///
/// Deliberately a button, not a live input: tapping it opens the dedicated
/// search screen (which owns the filter chips and results), so the Home feed
/// never has to host a keyboard.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      borderRadius: AppRadius.rXl,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rXl,
        child: Container(
          height: AppSizes.controlHeight.h,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.base.w),
          decoration: BoxDecoration(
            borderRadius: AppRadius.rXl,
            border: Border.all(color: AppColors.authInk, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: AppSizes.xl2.w,
                color: AppColors.fieldHint,
              ),
              AppSpacing.gapH(AppSpacing.sm),
              Expanded(
                child: Text(
                  AppStrings.searchSpecialty.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.rc(AppColors.fieldHint),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
