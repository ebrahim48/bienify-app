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
    this.horizontalPadding = AppSpacing.base,
    this.unselectedFill = AppColors.surface,
    this.unselectedInk = AppColors.gray900,
    this.unselectedBorder = AppColors.surfaceBorder,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Segmented controls sit a size up from filter chips.
  final bool isLarge;

  /// Inset each side of a label. Results to Review's three segments only fit
  /// a 390pt frame at the design's tighter 12pt; everywhere else keeps 16.
  final double horizontalPadding;

  /// How an unselected pill is drawn. The default is the outlined white one
  /// every screen uses; Results to Review's second row fills them slate
  /// instead, which is the only place the design departs.
  final Color unselectedFill;
  final Color unselectedInk;
  final Color unselectedBorder;

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
              horizontalPadding: horizontalPadding,
              fill: unselectedFill,
              ink: unselectedInk,
              border: unselectedBorder,
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
    required this.horizontalPadding,
    required this.fill,
    required this.ink,
    required this.border,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isLarge;
  final double horizontalPadding;
  final Color fill;
  final Color ink;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.actionFill : fill,
      borderRadius: AppRadius.rFull,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding.w,
            vertical: isLarge ? AppSpacing.sm.h : AppSpacing.xs.h,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.rFull,
            border: Border.all(
              color: isSelected ? AppColors.transparent : border,
              width: AppSizes.borderWidth,
            ),
          ),
          // Both sizes set 16pt type in the designs; the segmented control is
          // taller and bolder, not wider-set.
          child: Text(
            label,
            style:
                (isLarge ? AppTextStyles.titleSmall : AppTextStyles.bodyLarge)
                    .rc(isSelected ? AppColors.white : ink),
          ),
        ),
      ),
    );
  }
}
