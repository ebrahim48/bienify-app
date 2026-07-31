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

/// `Map | List` segmented control.
///
/// Hugs its content rather than filling the row, matching the design where it
/// sits against the left gutter.
class MapListToggle extends StatelessWidget {
  const MapListToggle({
    super.key,
    required this.isMapSelected,
    required this.onMap,
    required this.onList,
  });

  final bool isMapSelected;
  final VoidCallback onMap;
  final VoidCallback onList;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.xs2.w),
        decoration: BoxDecoration(
          color: AppColors.segmentTrack,
          borderRadius: AppRadius.rFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Segment(
              icon: Icons.map_outlined,
              label: AppStrings.mapView.tr,
              isSelected: isMapSelected,
              onTap: onMap,
            ),
            AppSpacing.gapH(AppSpacing.xs2),
            _Segment(
              icon: Icons.format_list_bulleted_rounded,
              label: AppStrings.listView.tr,
              isSelected: !isMapSelected,
              onTap: onList,
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = isSelected ? AppColors.white : AppColors.gray500;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.base.w,
          vertical: AppSpacing.xs.h,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.codeSurface : AppColors.transparent,
          borderRadius: AppRadius.rFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSizes.lg.w, color: ink),
            AppSpacing.gapH(AppSpacing.xs),
            Text(label, style: AppTextStyles.titleSmall.rc(ink)),
          ],
        ),
      ),
    );
  }
}
