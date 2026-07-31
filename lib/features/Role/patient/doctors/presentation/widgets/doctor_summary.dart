import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../domain/entities/doctor.dart';

/// Name and specialty on the left, rating and fee on the right.
class DoctorSummary extends StatelessWidget {
  const DoctorSummary({super.key, required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctor.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleLarge.rc(AppColors.authInk),
              ),
              AppSpacing.gapV(AppSpacing.xs2),
              Text(
                doctor.specialty,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLarge.rc(AppColors.textSecondary),
              ),
            ],
          ),
        ),
        AppSpacing.gapH(AppSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_rounded,
                  size: AppSizes.xl.w,
                  color: AppColors.star,
                ),
                AppSpacing.gapH(AppSpacing.xs2),
                Text(
                  doctor.ratingLabel,
                  style: AppTextStyles.titleSmall.rc(AppColors.black),
                ),
                Text(
                  AppStrings.reviewsCount.trParams({
                    'count': '${doctor.reviewCount}',
                  }),
                  style: AppTextStyles.bodyMedium.rc(AppColors.black),
                ),
              ],
            ),
            AppSpacing.gapV(AppSpacing.xs),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '\$${doctor.consultationFee.toStringAsFixed(0)}',
                  style: AppTextStyles.titleLarge.rc(AppColors.primary500),
                ),
                Text(
                  AppStrings.perConsultation.tr,
                  style: AppTextStyles.bodyMedium.rc(AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
