import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

/// `Prompt?  Action` row — the pattern used under almost every form
/// ("Already have an account? **Login**", "Code not received?
/// **Request New OTP**", "Forgot your password? **Reset Now**").
///
/// The prompt is regular body text and the action is the same size in
/// semi-bold, both in the navy auth ink, exactly as drawn.
class AppInlineLink extends StatelessWidget {
  const AppInlineLink({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
    this.alignment = MainAxisAlignment.start,
    this.isEnabled = true,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;
  final MainAxisAlignment alignment;

  /// Dims the action and blocks taps (used while an OTP resend cools down).
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      children: [
        Flexible(
          child: Text(
            prompt,
            style: AppTextStyles.bodyMedium.rc(AppColors.authInk),
          ),
        ),
        AppSpacing.gapH(AppSpacing.xs),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isEnabled ? onTap : null,
          child: Text(
            action,
            style: AppTextStyles.labelLarge.rc(
              isEnabled ? AppColors.authInk : AppColors.gray400,
            ),
          ),
        ),
      ],
    );
  }
}

/// Standalone underlined action, used for "Join as a Doctor".
class AppUnderlinedLink extends StatelessWidget {
  const AppUnderlinedLink({
    super.key,
    required this.label,
    required this.onTap,
    this.color = AppColors.authInk,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTextStyles.titleSmall
            .rc(color)
            .copyWith(
              decoration: TextDecoration.underline,
              decorationColor: color,
            ),
      ),
    );
  }
}
