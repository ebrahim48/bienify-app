import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import 'blurred_dialog.dart';

/// A question with a deny and a confirm button side by side, over the same
/// blurred page as every other dialog in the app.
///
/// Resolves to `true` when confirmed and `null` when dismissed, so a caller
/// can simply `if (await AppConfirmDialog.show(...) ?? false)`.
///
/// ```dart
/// final ok = await AppConfirmDialog.show(
///   context,
///   question: AppStrings.readyToLogOut.tr,
///   confirmLabel: AppStrings.logOut.tr,
///   confirmColor: AppColors.logoutFill,
/// );
/// ```
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.question,
    required this.confirmLabel,
    required this.denyLabel,
    this.confirmColor = AppColors.actionFill,
  });

  final String question;
  final String confirmLabel;
  final String denyLabel;

  /// Fill of the confirm button — destructive actions pass
  /// [AppColors.logoutFill].
  final Color confirmColor;

  static Future<bool?> show(
    BuildContext context, {
    required String question,
    required String confirmLabel,
    required String denyLabel,
    Color confirmColor = AppColors.actionFill,
  }) {
    return showBlurredDialog<bool>(
      context: context,
      builder: (_) => AppConfirmDialog(
        question: question,
        confirmLabel: confirmLabel,
        denyLabel: denyLabel,
        confirmColor: confirmColor,
      ),
    );
  }

  /// The two buttons are pills, shorter than the app's 50pt action height —
  /// this is a dialog, not a page action.
  static const double _buttonHeight = 38;

  @override
  Widget build(BuildContext context) {
    return AppDialogCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md.w,
        vertical: AppSpacing.base.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            question,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium.rc(AppColors.gray900),
          ),
          AppSpacing.gapV(AppSpacing.base),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Pill(
                label: denyLabel,
                fill: AppColors.denyFill,
                ink: AppColors.gray900,
                onTap: () => Navigator.of(context).pop(),
              ),
              AppSpacing.gapH(AppSpacing.base),
              _Pill(
                label: confirmLabel,
                fill: confirmColor,
                ink: AppColors.white,
                onTap: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.fill,
    required this.ink,
    required this.onTap,
  });

  final String label;
  final Color fill;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fill,
      borderRadius: AppRadius.rFull,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: AppConfirmDialog._buttonHeight.h,
          constraints: BoxConstraints(minWidth: AppSizes.dialogPillWidth.w),
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
          alignment: Alignment.center,
          child: Text(label, style: AppTextStyles.titleSmall.rc(ink)),
        ),
      ),
    );
  }
}
