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

/// Live "Search Specialty" input.
///
/// Shares the Home search bar's navy outline and 12pt radius, but this one
/// actually accepts text — Home's is a button that opens this screen.
///
/// **This widget owns its `TextEditingController`.** Callers pass
/// [initialText] and listen through [onChanged]; a GetX controller must not
/// hold the text controller, because GetX disposes route dependencies while
/// the outgoing route is still painting its pop transition, and the field
/// would then rebuild against a disposed controller.
class DoctorSearchField extends StatefulWidget {
  const DoctorSearchField({
    super.key,
    required this.onChanged,
    this.initialText = '',
    this.autofocus = false,
    this.onSubmitted,
    this.hintKey = AppStrings.searchSpecialty,
  });

  /// Text to seed the field with, so a query survives leaving the screen.
  final String initialText;

  final ValueChanged<String> onChanged;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  /// Translation key for the placeholder; Pharmacy passes its own.
  final String hintKey;

  @override
  State<DoctorSearchField> createState() => _DoctorSearchFieldState();
}

class _DoctorSearchFieldState extends State<DoctorSearchField> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initialText,
  );

  @override
  void didUpdateWidget(DoctorSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Lets a "clear" action upstream reset the field, without stomping on
    // what the user is currently typing.
    if (widget.initialText != oldWidget.initialText &&
        widget.initialText != _text.text) {
      _text.text = widget.initialText;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.controlHeight.h,
      child: TextField(
        controller: _text,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        autofocus: widget.autofocus,
        textInputAction: TextInputAction.search,
        textAlignVertical: TextAlignVertical.center,
        cursorColor: AppColors.primary800,
        style: AppTextStyles.bodyLarge.rc(AppColors.authInk),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.transparent,
          hintText: widget.hintKey.tr,
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
