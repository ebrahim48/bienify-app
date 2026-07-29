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
import '../../../../core/widgets/blurred_dialog.dart';

/// "Cancel Reason" — a free-text reason over a blurred page, with the
/// destructive confirm.
///
/// ```dart
/// final reason = await CancelReasonDialog.show(context);
/// if (reason != null) controller.cancel(appointment, reason);
/// ```
class CancelReasonDialog extends StatefulWidget {
  const CancelReasonDialog({super.key});

  /// Resolves to the typed reason, or `null` if dismissed.
  static Future<String?> show(BuildContext context) {
    return showBlurredDialog<String>(
      context: context,
      builder: (_) => const CancelReasonDialog(),
    );
  }

  @override
  State<CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<CancelReasonDialog> {
  // Pre-filled with the design's copy so the field is never an empty box on
  // first open; the patient can replace it.
  late final TextEditingController _reason = TextEditingController(
    text: AppStrings.cancelReasonHint.tr,
  );

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.cancelReason.tr,
                style: AppTextStyles.titleLarge.rw(
                  AppColors.gray900,
                  FontWeight.w400,
                ),
              ),
              InkResponse(
                onTap: () => Navigator.of(context).pop(),
                radius: AppSizes.xl2.r,
                child: Icon(
                  Icons.close_rounded,
                  size: AppSizes.xl2.w,
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),
          AppSpacing.gapV(AppSpacing.base),
          Container(
            padding: EdgeInsets.all(AppSpacing.sm.w),
            decoration: BoxDecoration(
              borderRadius: AppRadius.rXl,
              border: Border.all(
                color: AppColors.surfaceBorder,
                width: AppSizes.borderWidth,
              ),
            ),
            child: TextField(
              controller: _reason,
              maxLines: 4,
              minLines: 3,
              cursorColor: AppColors.primary800,
              style: AppTextStyles.bodyLarge.rc(AppColors.gray700),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: AppColors.error600,
              borderRadius: AppRadius.rLg,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(_reason.text.trim()),
                child: Container(
                  height: AppSizes.controlHeight.h,
                  alignment: Alignment.center,
                  child: Text(
                    AppStrings.cancelNow.tr,
                    style: AppTextStyles.titleSmall.rc(AppColors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
