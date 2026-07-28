import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';

/// Live "Search Specialty" input.
///
/// Shares the Home search bar's navy outline and 12pt radius, but this one
/// actually accepts text — Home's is a button that opens this screen.
class DoctorSearchField extends StatelessWidget {
  const DoctorSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.controlHeight.h,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        autofocus: autofocus,
        textInputAction: TextInputAction.search,
        textAlignVertical: TextAlignVertical.center,
        cursorColor: AppColors.primary800,
        style: AppTextStyles.bodyLarge.rc(AppColors.authInk),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.transparent,
          hintText: AppStrings.searchSpecialty.tr,
          hintStyle: AppTextStyles.bodyLarge.rc(AppColors.fieldHint),
          contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h),
          prefixIcon: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.base.w),
            child: Icon(
              Icons.search_rounded,
              size: AppSizes.xl2.w,
              color: AppColors.fieldHint,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          border: _border(AppColors.authInk),
          enabledBorder: _border(AppColors.authInk),
          focusedBorder: _border(AppColors.authInk),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: AppRadius.rXl,
    borderSide: BorderSide(color: color, width: 1.5),
  );
}
