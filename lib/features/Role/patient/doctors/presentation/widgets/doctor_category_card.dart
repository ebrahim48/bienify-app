import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../domain/entities/doctor_category.dart';

/// Glyph for a specialty tile.
///
/// One mapper so the grid cannot drift from any future list view.
///
/// Note: the design draws bespoke line illustrations (lungs, brain, stomach,
/// a seated figure). Only the last two have close Material equivalents, so
/// exporting `lungs.svg` and `stomach.svg` into `assets/icons` and switching
/// this function to `AppSvgIcon` is what makes the grid pixel-exact.
IconData iconForCategory(String categoryId) => switch (categoryId) {
  'internal-medicine' => Icons.monitor_heart_outlined,
  'neuromedicine' => Icons.psychology_outlined,
  'general-physician' => Icons.self_improvement_outlined,
  'gastroenterology' => Icons.local_hospital_outlined,
  'urology' => Icons.water_drop_outlined,
  'oncology' => Icons.biotech_outlined,
  'cardiology' => Icons.favorite_border_rounded,
  'dermatology' => Icons.face_retouching_natural_outlined,
  'pediatrics' => Icons.child_care_outlined,
  'orthopedics' => Icons.accessibility_new_rounded,
  _ => Icons.medical_services_outlined,
};

/// A specialty tile: outline glyph over a centred label.
///
/// [DoctorCategoryCard.wide] is the full-width variant used for the
/// catch-all "General" entry, which carries no icon.
class DoctorCategoryCard extends StatelessWidget {
  const DoctorCategoryCard({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  }) : isWide = false;

  const DoctorCategoryCard.wide({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  }) : isWide = true;

  final DoctorCategory category;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isWide;

  static const double gridHeight = 98;
  static const double wideHeight = 78;
  static const double _icon = 44;

  @override
  Widget build(BuildContext context) {
    final ink = isSelected ? AppColors.white : AppColors.gray900;

    return Material(
      color: isSelected ? AppColors.actionFill : AppColors.surface,
      borderRadius: AppRadius.rXl,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          height: (isWide ? wideHeight : gridHeight).h,
          decoration: BoxDecoration(
            borderRadius: AppRadius.rXl,
            border: Border.all(
              color: isSelected
                  ? AppColors.actionFill
                  : AppColors.surfaceBorder,
              width: AppSizes.borderWidth,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isWide) ...[
                Icon(iconForCategory(category.id), size: _icon.w, color: ink),
                AppSpacing.gapV(AppSpacing.xs),
              ],
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.rc(ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
