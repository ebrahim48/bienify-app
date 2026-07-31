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
import '../../../../../../core/widgets/app_avatar.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../domain/entities/doctor.dart';

/// A doctor row: photo, name, specialty with rating, and the availability
/// call to action.
///
/// Used by both the Home feed and the search results, so the row never has to
/// be rebuilt for the second screen.
class DoctorListCard extends StatelessWidget {
  const DoctorListCard({
    super.key,
    required this.doctor,
    required this.onTap,
    this.onSeeAvailability,
  });

  final Doctor doctor;
  final VoidCallback onTap;

  /// Defaults to [onTap] when omitted.
  final VoidCallback? onSeeAvailability;

  static const double _avatarSize = 44;

  /// Fixed so the name and specialty always get the remaining 170pt the
  /// design allots them, instead of being squeezed by a wider label.
  static const double _actionWidth = 100;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm.w,
        vertical: AppSpacing.sm.h,
      ),
      child: Row(
        children: [
          AppAvatar(
            imageUrl: doctor.photoUrl,
            name: doctor.name,
            size: _avatarSize,
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  doctor.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge.rc(AppColors.authInk),
                ),
                AppSpacing.gapV(AppSpacing.xs2),
                _SpecialtyRating(doctor: doctor),
              ],
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          SizedBox(
            width: _actionWidth.w,
            child: _AvailabilityButton(onTap: onSeeAvailability ?? onTap),
          ),
        ],
      ),
    );
  }
}

class _SpecialtyRating extends StatelessWidget {
  const _SpecialtyRating({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    final muted = AppTextStyles.bodySmall.rc(AppColors.textSecondary);

    return Row(
      children: [
        Flexible(
          child: Text(
            doctor.specialty,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: muted,
          ),
        ),
        AppSpacing.gapH(AppSpacing.xs2),
        Container(
          width: AppSizes.borderWidth,
          height: AppSizes.base.h,
          color: AppColors.gray200,
        ),
        AppSpacing.gapH(AppSpacing.xs2),
        Icon(Icons.star_rounded, size: AppSizes.lg.w, color: AppColors.star),
        AppSpacing.gapH(AppSpacing.xxs),
        Text('${doctor.ratingLabel} ${doctor.reviewCountLabel}', style: muted),
      ],
    );
  }
}

class _AvailabilityButton extends StatelessWidget {
  const _AvailabilityButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.actionFill,
      borderRadius: AppRadius.rLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: AppSizes.xl3.h,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs.w),
          alignment: Alignment.center,
          child: FittedBox(
            child: Text(
              AppStrings.seeAvailability.tr,
              maxLines: 1,
              style: AppTextStyles.bodySmall.rc(AppColors.actionLabel),
            ),
          ),
        ),
      ),
    );
  }
}
