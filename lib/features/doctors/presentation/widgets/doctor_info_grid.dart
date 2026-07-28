import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/doctor_details.dart';

/// The 2×2 stat block: experience and patient count on top (icon + value +
/// caption), working time and languages below (caption + value).
class DoctorInfoGrid extends StatelessWidget {
  const DoctorInfoGrid({super.key, required this.details});

  final DoctorDetails details;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Pair(
          left: _IconStat(
            icon: AppIcons.clock,
            value: AppStrings.yearsCount.trParams({
              'count': '${details.experienceYears}',
            }),
            caption: AppStrings.experience.tr,
          ),
          right: _IconStat(
            icon: AppIcons.person,
            value: details.patientCount,
            caption: AppStrings.patients.tr,
          ),
        ),
        AppSpacing.gapV(AppSpacing.sm),
        _Pair(
          left: _LabelledStat(
            caption: AppStrings.workingTime.tr,
            value: details.workingTime,
          ),
          right: _LabelledStat(
            caption: details.languagesLabel,
            value: details.languagesLabel,
          ),
        ),
      ],
    );
  }
}

/// Two cards side by side.
///
/// Deliberately unconstrained in height: both sides always hold the same
/// shape of content (single-line value over single-line caption), so they
/// size identically on their own. A fixed height would have to be re-tuned
/// whenever type metrics scale — `.sp` and `.h` do not move together — and a
/// few tenths of a pixel of drift is enough to overflow.
///
/// `IntrinsicHeight` is not used either: `RenderFlex` cannot report
/// intrinsics for a row of `Expanded` children.
class _Pair extends StatelessWidget {
  const _Pair({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        AppSpacing.gapH(AppSpacing.sm),
        Expanded(child: right),
      ],
    );
  }
}

class _IconStat extends StatelessWidget {
  const _IconStat({
    required this.icon,
    required this.value,
    required this.caption,
  });

  final String icon;
  final String value;
  final String caption;

  static const double _badge = 44;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm.w,
        vertical: AppSpacing.sm.h,
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
              icon,
              size: AppSizes.xl2,
              color: AppColors.primary600,
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.rc(AppColors.black),
                ),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.rc(AppColors.gray800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelledStat extends StatelessWidget {
  const _LabelledStat({required this.caption, required this.value});

  final String caption;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm.w,
        vertical: AppSpacing.sm.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.rc(AppColors.textSecondary),
          ),
          AppSpacing.gapV(AppSpacing.xs2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelLarge.rc(AppColors.authInk),
          ),
        ],
      ),
    );
  }
}
