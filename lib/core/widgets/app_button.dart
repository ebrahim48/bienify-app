import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

enum AppButtonVariant { primary, secondary }

/// Reusable button following the design spec:
///   Primary  — w:362 h:56 bg:#1C1C1E radius:16 padding:12/24
///   Secondary — w:362 h:54 bg:#FFFFFF radius:12 border:1px #E6E6E6 padding:14/24
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.width = double.infinity,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final double width;

  bool get _isPrimary => variant == AppButtonVariant.primary;

  @override
  Widget build(BuildContext context) {
    final double height     = _isPrimary ? 56.0 : 54.0;
    final double radius     = _isPrimary ? 16.0 : 12.0;
    final Color  bgColor    = _isPrimary ? AppColors.primary : AppColors.white;
    final Color  textColor  = _isPrimary ? AppColors.white   : AppColors.textSecondary;
    final Border? border    = _isPrimary
        ? null
        : Border.all(color: AppColors.border, width: 1);

    return SizedBox(
      width: width,
      height: height,
      child: GestureDetector(
        onTap: isLoading ? null : onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(radius),
            border: border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isPrimary ? AppColors.white : AppColors.primary,
                    ),
                  ),
                )
              : Text(
                  label,
                  style: AppTextStyles.buttonLabel.copyWith(color: textColor),
                ),
        ),
      ),
    );
  }
}
