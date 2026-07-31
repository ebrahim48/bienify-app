import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_card.dart';

/// Photo, name, one grey line under it and a date on the right.
///
/// The same 358×70 card appears three times in Results to Review — the
/// patient list, the patient screen and Order Additional Test — with only the
/// second line changing, so it is one widget.
class PatientRowCard extends StatelessWidget {
  const PatientRowCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.dateLabel,
    this.photoAsset,
    this.onTap,
  });

  final String name;

  /// `CXR-2` in the list, the complaint on the patient screen.
  final String subtitle;

  final String dateLabel;
  final String? photoAsset;
  final VoidCallback? onTap;

  /// A rounded square, not the circular [AppAvatar] the rest of the app uses —
  /// these designs crop the photo square.
  static const double _photo = 46;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      hasShadow: false,
      borderColor: AppColors.chipSurface,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.base.w,
        vertical: AppSpacing.sm.h,
      ),
      child: Row(
        children: [
          _Photo(asset: photoAsset),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.rw(
                    AppColors.gray900,
                    FontWeight.w400,
                  ),
                ),
                AppSpacing.gapV(AppSpacing.xs2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
                ),
              ],
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Text(dateLabel, style: AppTextStyles.bodyLarge.rc(AppColors.gray500)),
        ],
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({this.asset});

  final String? asset;

  @override
  Widget build(BuildContext context) {
    final side = PatientRowCard._photo.w;

    return Container(
      width: side,
      height: side,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.chipSurface,
        borderRadius: AppRadius.rXl,
      ),
      child: asset == null
          ? Icon(
              Icons.person_rounded,
              size: side * 0.55,
              color: AppColors.gray500,
            )
          : Image.asset(
              asset!,
              fit: BoxFit.cover,
              errorBuilder: (context, _, _) => Icon(
                Icons.person_rounded,
                size: side * 0.55,
                color: AppColors.gray500,
              ),
            ),
    );
  }
}
