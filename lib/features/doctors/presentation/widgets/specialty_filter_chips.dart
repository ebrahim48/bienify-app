import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../controllers/doctor_search_controller.dart';

/// The wrapping row of specialty pills above the search results.
///
/// "All" is always first and clears the filter; the selected pill fills
/// `primary500` with white text, the rest are white.
class SpecialtyFilterChips extends StatelessWidget {
  const SpecialtyFilterChips({
    super.key,
    required this.specialties,
    required this.selected,
    required this.onSelected,
  });

  final List<String> specialties;

  /// The active specialty, or [DoctorSearchController.allSpecialties].
  ///
  /// A plain value rather than a predicate so the caller's `Obx` actually
  /// reads the observable and rebuilds when it changes.
  final String selected;

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs.w,
      runSpacing: AppSpacing.xs.h,
      children: [
        _Chip(
          label: AppStrings.filterAll.tr,
          isSelected: selected == DoctorSearchController.allSpecialties,
          onTap: () => onSelected(DoctorSearchController.allSpecialties),
        ),
        for (final specialty in specialties)
          _Chip(
            label: specialty,
            isSelected: selected == specialty,
            onTap: () => onSelected(specialty),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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
      color: isSelected ? AppColors.primary500 : AppColors.surface,
      borderRadius: AppRadius.rFull,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        // No `alignment:` and no fixed height — either would make the chip
        // expand to the full row width inside a `Wrap`.
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.base.w,
            vertical: AppSpacing.xs.h,
          ),
          child: Text(
            label,
            maxLines: 1,
            style: AppTextStyles.bodyMedium.rc(
              isSelected ? AppColors.white : AppColors.gray900,
            ),
          ),
        ),
      ),
    );
  }
}
