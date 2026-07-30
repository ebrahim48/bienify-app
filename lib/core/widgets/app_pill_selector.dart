import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

/// A horizontally scrolling row of pills, exactly one of which is filled.
///
/// The designs use this shape in two sizes: a large two-option segmented
/// control ("Lab Reports | Radiology Reports", "Your Prescriptions | Your
/// Medical vault") and a smaller filter row ("all · Active Orders · …",
/// "All · Delivered · Pending · Cancelled").
///
/// Scrolling rather than wrapping because the designs keep every option on one
/// line, and the widest sets do not fit at 320pt.
///
/// ```dart
/// Obx(() => AppPillSelector(
///   labels: [for (final t in Tab.values) t.label],
///   selectedIndex: Tab.values.indexOf(controller.tab.value),
///   onSelected: (i) => controller.select(Tab.values[i]),
///   isLarge: true,
/// ))
/// ```
class AppPillSelector extends StatelessWidget {
  const AppPillSelector({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.isLarge = false,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Segmented controls sit a size up from filter chips.
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++) ...[
            if (index > 0) AppSpacing.gapH(AppSpacing.xs),
            _Pill(
              label: labels[index],
              isSelected: index == selectedIndex,
              isLarge: isLarge,
              onTap: () => onSelected(index),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.isSelected,
    required this.isLarge,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isLarge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.actionFill : AppColors.surface,
      borderRadius: AppRadius.rFull,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.base.w,
            vertical: isLarge ? AppSpacing.sm.h : AppSpacing.xs.h,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.rFull,
            border: Border.all(
              color: isSelected
                  ? AppColors.transparent
                  : AppColors.surfaceBorder,
              width: AppSizes.borderWidth,
            ),
          ),
          // Both sizes set 16pt type in the designs; the segmented control is
          // taller and bolder, not wider-set.
          child: Text(
            label,
            style: (isLarge
                    ? AppTextStyles.titleSmall
                    : AppTextStyles.bodyLarge)
                .rc(isSelected ? AppColors.white : AppColors.gray900),
          ),
        ),
      ),
    );
  }
}
