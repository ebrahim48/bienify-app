import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

/// The one input used across the app.
///
/// Matches the spec exactly: 358×50, `lg` (8px) radius, 1px `gray100` border,
/// white fill, `gray600` placeholder. Errors are rendered *below* the box so
/// the 50pt height never changes and the layout does not jump.
///
/// ```dart
/// AppTextField(
///   hint: AppStrings.emailHint.tr,
///   controller: controller.emailController,
///   keyboardType: TextInputType.emailAddress,
///   errorText: controller.emailError.value,
/// )
/// ```
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.showPasswordToggle = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    this.autofillHints,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.textAlign = TextAlign.start,
    this.letterSpacing,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
  });

  final TextEditingController? controller;
  final String? hint;

  /// Validation message; when non-null the border turns red and the message
  /// is shown underneath.
  final String? errorText;

  final Widget? prefixIcon;
  final Widget? suffixIcon;

  final bool obscureText;

  /// Adds the eye / eye-off affordance seen on every password field.
  final bool showPasswordToggle;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final Iterable<String>? autofillHints;

  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;

  final TextAlign textAlign;

  /// Extra tracking, used by the OTP input.
  final double? letterSpacing;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;

  bool get _hasError => widget.errorText != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: AppSizes.controlHeight.h,
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            obscureText: _obscured,
            obscuringCharacter: '•',
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            inputFormatters: widget.inputFormatters,
            maxLength: widget.maxLength,
            autofillHints: widget.autofillHints,
            textAlign: widget.textAlign,
            textAlignVertical: TextAlignVertical.center,
            cursorColor: AppColors.primary800,
            style: AppTextStyles.bodyMedium.rc(AppColors.authInk).copyWith(
              letterSpacing: widget.letterSpacing,
            ),
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            decoration: InputDecoration(
              isDense: true,
              counterText: '',
              filled: true,
              fillColor: widget.enabled
                  ? AppColors.fieldFill
                  : AppColors.gray50,
              hintText: widget.hint,
              hintStyle: AppTextStyles.bodyMedium
                  .rc(AppColors.fieldHint)
                  .copyWith(letterSpacing: widget.letterSpacing),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.base.w,
                vertical: AppSpacing.sm.h,
              ),
              prefixIcon: _pad(widget.prefixIcon),
              prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: _pad(_suffix()),
              suffixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
              border: _border(AppColors.fieldBorder),
              enabledBorder: _border(
                _hasError ? AppColors.error : AppColors.fieldBorder,
              ),
              focusedBorder: _border(
                _hasError ? AppColors.error : AppColors.primary800,
              ),
              disabledBorder: _border(AppColors.fieldBorder),
            ),
          ),
        ),
        if (_hasError) ...[
          AppSpacing.gapV(AppSpacing.xs2 + 2),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs2.w),
            child: Text(
              widget.errorText!,
              style: AppTextStyles.bodySmall.rc(AppColors.error),
            ),
          ),
        ],
      ],
    );
  }

  Widget? _suffix() {
    if (widget.showPasswordToggle) {
      return _PasswordToggle(
        obscured: _obscured,
        onTap: () => setState(() => _obscured = !_obscured),
      );
    }
    return widget.suffixIcon;
  }

  /// Keeps prefix/suffix widgets on the 16px gutter without letting Flutter
  /// inflate them to the default 48px touch box.
  Widget? _pad(Widget? child) {
    if (child == null) return null;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.base.w),
      child: child,
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: AppRadius.rLg,
    borderSide: BorderSide(color: color, width: AppSizes.borderWidth),
  );
}

/// Eye / eye-off affordance matching the design's `gray600` outline icon.
class _PasswordToggle extends StatelessWidget {
  const _PasswordToggle({required this.obscured, required this.onTap});

  final bool obscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Icon(
        obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: AppSizes.xl2.w,
        color: AppColors.fieldHint,
      ),
    );
  }
}
