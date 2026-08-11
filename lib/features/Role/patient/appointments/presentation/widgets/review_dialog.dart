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
import '../../../../../../core/widgets/blurred_dialog.dart';

/// "How was Your Experience?" — a five-star rating over a blurred page.
///
/// ```dart
/// final stars = await ReviewDialog.show(context);
/// ```
class ReviewDialog extends StatefulWidget {
  const ReviewDialog({super.key, this.initialRating = 4});

  /// The design shows four of five filled on open.
  final int initialRating;

  /// Resolves to the chosen star count, or `null` if dismissed.
  static Future<int?> show(BuildContext context) {
    return showBlurredDialog<int>(
      context: context,
      builder: (_) => const ReviewDialog(),
    );
  }

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  late int _rating = widget.initialRating;

  static const int _maxStars = 5;
  static const double _star = 32;

  @override
  Widget build(BuildContext context) {
    return AppDialogCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: InkResponse(
              onTap: () => Navigator.of(context).pop(),
              radius: AppSizes.xl2.r,
              child: Icon(
                Icons.close_rounded,
                size: AppSizes.xl2.w,
                color: AppColors.gray900,
              ),
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          Text(
            AppStrings.howWasYourExperience.tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge.rw(
              AppColors.authInk,
              FontWeight.w400,
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var star = 1; star <= _maxStars; star++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _rating = star),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxs.w),
                    child: Icon(
                      Icons.star_rounded,
                      size: _star.w,
                      color: star <= _rating
                          ? AppColors.star
                          : AppColors.gray200,
                    ),
                  ),
                ),
            ],
          ),
          AppSpacing.gapV(AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: AppColors.actionFill,
              borderRadius: AppRadius.rLg,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(_rating),
                child: Container(
                  height: AppSizes.controlHeight.h,
                  alignment: Alignment.center,
                  child: Text(
                    AppStrings.submitReview.tr,
                    style: AppTextStyles.titleSmall.rc(AppColors.actionLabel),
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
