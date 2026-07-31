import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';

/// A `value ⌄` selector styled like the app's inputs.
///
/// Used by Set Schedule's year / month / week pickers and the fees sheet's
/// currency — four places with the same shape.
class AppDropdownField extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.controlHeight.h,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.base.w),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: AppRadius.rLg,
        border: Border.all(
          color: AppColors.fieldBorder,
          width: AppSizes.borderWidth,
        ),
      ),
      alignment: Alignment.center,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: AppSizes.xl2.w,
            color: AppColors.gray900,
          ),
          borderRadius: AppRadius.rLg,
          style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
          items: [
            for (final option in options)
              DropdownMenuItem<String>(value: option, child: Text(option)),
          ],
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
      ),
    );
  }
}
