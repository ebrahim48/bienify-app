import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../constants/app_strings.dart';
import '../models/country.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import 'country_picker_sheet.dart';

/// Phone input with an inline country selector, used by the onboarding panel
/// and the standalone "Enter Phone Number" screen.
///
/// The two designs differ only in fill and corner radius, so both are covered
/// by [AppPhoneField.panel] and the default constructor rather than by two
/// widgets:
///
/// ```dart
/// // Standalone screen: white fill, 8px radius, 1px border.
/// AppPhoneField(
///   controller: c.phoneController,
///   country: c.country.value,
///   onCountryChanged: c.selectCountry,
/// )
///
/// // Onboarding panel: gray50 fill, 24px radius, no border.
/// AppPhoneField.panel(...)
/// ```
class AppPhoneField extends StatelessWidget {
  const AppPhoneField({
    super.key,
    required this.controller,
    required this.country,
    required this.onCountryChanged,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.fillColor = AppColors.fieldFill,
    this.borderColor = AppColors.fieldBorder,
    this.radius = AppRadius.lg,
  });

  /// Onboarding-panel styling: warm off-white fill, fully rounded, borderless.
  const AppPhoneField.panel({
    super.key,
    required this.controller,
    required this.country,
    required this.onCountryChanged,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
  }) : fillColor = AppColors.gray50,
       borderColor = AppColors.transparent,
       radius = AppRadius.xl3;

  final TextEditingController controller;
  final Country country;
  final ValueChanged<Country> onCountryChanged;

  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  final Color fillColor;
  final Color borderColor;
  final double radius;

  /// Width of the country block, measured from the design (16 → 129).
  static const double _countryBlockWidth = 113;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: AppSizes.controlHeight.h,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(radius.r),
            border: Border.all(
              color: hasError ? AppColors.error : borderColor,
              width: AppSizes.borderWidth,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: _countryBlockWidth.w,
                child: _CountrySelector(
                  country: country,
                  onTap: () async {
                    FocusScope.of(context).unfocus();
                    final selected = await CountryPickerSheet.show(
                      context,
                      selected: country,
                    );
                    if (selected != null) onCountryChanged(selected);
                  },
                ),
              ),
              Container(
                width: AppSizes.borderWidth,
                height: double.infinity,
                color: AppColors.gray200,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  textInputAction: textInputAction,
                  textAlignVertical: TextAlignVertical.center,
                  cursorColor: AppColors.primary800,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                  autofillHints: const [AutofillHints.telephoneNumber],
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  style: AppTextStyles.bodyMedium.rc(AppColors.authInk),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: AppStrings.enterPhoneNumber.tr,
                    hintStyle: AppTextStyles.bodyMedium.rc(AppColors.fieldHint),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.base.w,
                      vertical: AppSpacing.sm.h,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          AppSpacing.gapV(AppSpacing.xs2 + 2),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs2.w),
            child: Text(
              errorText!,
              style: AppTextStyles.bodySmall.rc(AppColors.error),
            ),
          ),
        ],
      ],
    );
  }
}

class _CountrySelector extends StatelessWidget {
  const _CountrySelector({required this.country, required this.onTap});

  final Country country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.base.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(country.flagEmoji, style: TextStyle(fontSize: AppSizes.lg.sp)),
            Flexible(
              child: Text(
                country.dialCode,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.rc(AppColors.authInk),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: AppSizes.xl2.w,
              color: AppColors.authInk,
            ),
          ],
        ),
      ),
    );
  }
}
