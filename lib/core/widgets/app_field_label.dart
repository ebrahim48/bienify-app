import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

/// `Name*`-style field label — navy `labelLarge` text with the required
/// marker appended in the same weight, exactly as drawn in the designs.
class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel(this.text, {super.key, this.isRequired = true});

  final String text;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Text(
      isRequired ? '$text*' : text,
      style: AppTextStyles.labelLarge.rc(AppColors.authInk),
    );
  }
}

/// A label stacked on top of any input, with the design's 8px gap.
///
/// Use it instead of hand-rolling `Column(children: [label, gap, field])` so
/// spacing stays identical on every form.
///
/// ```dart
/// AppLabeledField(
///   label: AppStrings.email.tr,
///   child: AppTextField(hint: AppStrings.emailHint.tr),
/// )
/// ```
class AppLabeledField extends StatelessWidget {
  const AppLabeledField({
    super.key,
    required this.label,
    required this.child,
    this.isRequired = true,
    this.gap = AppSpacing.labelGap,
  });

  final String label;
  final Widget child;
  final bool isRequired;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppFieldLabel(label, isRequired: isRequired),
        AppSpacing.gapV(gap),
        child,
      ],
    );
  }
}
