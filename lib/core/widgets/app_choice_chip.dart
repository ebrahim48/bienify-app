import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

/// Compact single-select chip (the Age ranges on profile setup).
class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.actionFill : AppColors.fieldFill,
      borderRadius: AppRadius.rLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          height: AppSizes.choiceChipHeight.h,
          decoration: BoxDecoration(
            borderRadius: AppRadius.rLg,
            border: Border.all(
              color: isSelected ? AppColors.actionFill : AppColors.fieldBorder,
              width: AppSizes.borderWidth,
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              style: AppTextStyles.bodyMedium.rc(
                isSelected ? AppColors.white : AppColors.authInk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lays chips out on a fixed column grid so rows stay aligned exactly as in
/// the design (4 per row, 8pt gutters) instead of reflowing by text width.
///
/// ```dart
/// AppChoiceChipGrid(
///   columns: 4,
///   children: [for (final range in AgeRange.values) AppChoiceChip(...)],
/// )
/// ```
class AppChoiceChipGrid extends StatelessWidget {
  const AppChoiceChipGrid({
    super.key,
    required this.children,
    this.columns = 4,
    this.spacing = AppSpacing.xs,
    this.runSpacing = AppSpacing.xs + 2,
  });

  final List<Widget> children;
  final int columns;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = spacing.w;
        final itemWidth =
            (constraints.maxWidth - gutter * (columns - 1)) / columns;

        return Wrap(
          spacing: gutter,
          runSpacing: runSpacing.h,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
