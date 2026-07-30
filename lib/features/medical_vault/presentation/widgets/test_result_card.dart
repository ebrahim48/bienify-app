import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_tag.dart';
import '../../domain/entities/medical_record.dart';

/// One test order: its two category tags, the status pill, the study name,
/// who ordered it, where it is booked, and the action link at the foot.
class TestResultCard extends StatelessWidget {
  const TestResultCard({
    super.key,
    required this.order,
    required this.statusLabel,
    required this.actionLabel,
    required this.onAction,
  });

  final TestOrder order;
  final String statusLabel;
  final String actionLabel;
  final VoidCallback onAction;

  /// Green with a dot once read, orange while it sits with someone, amber
  /// while nothing has happened yet.
  (AppTagTone, bool) get _status => switch (order.stage) {
    TestStage.reviewed => (AppTagTone.success, true),
    TestStage.awaitingReview => (AppTagTone.warning, false),
    TestStage.awaitingUpload => (AppTagTone.warning, false),
    TestStage.requestSent => (AppTagTone.pending, false),
  };

  @override
  Widget build(BuildContext context) {
    final (tone, hasDot) = _status;

    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // A `Wrap`, not a `Row`: all three labels are fixed vocabulary and
          // must read in full, so on a narrow device the status pill drops to
          // a second line rather than any of them ellipsizing. `spaceBetween`
          // holds the status pill to the right edge while they share a line.
          Wrap(
            spacing: AppSpacing.xs.w,
            runSpacing: AppSpacing.xs2.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: AppSpacing.xs.w,
                runSpacing: AppSpacing.xs2.h,
                children: [
                  AppTag(order.category, tone: AppTagTone.info),
                  AppTag(order.priority),
                ],
              ),
              AppTag(statusLabel, tone: tone, hasDot: hasDot, pill: true),
            ],
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Text(
            order.title,
            style: AppTextStyles.titleMedium.rw(
              AppColors.gray900,
              FontWeight.w400,
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs2),
          Text(
            AppStrings.fromDoctor.trParams({'doctor': order.orderedBy}),
            style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
          ),
          if (order.facility != null) ...[
            AppSpacing.gapV(AppSpacing.xs2),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: AppSizes.lg.w,
                  color: AppColors.link,
                ),
                AppSpacing.gapH(AppSpacing.xs2),
                Expanded(
                  child: Text(
                    order.facility!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge.rc(AppColors.link),
                  ),
                ),
              ],
            ),
          ],
          AppSpacing.gapV(AppSpacing.sm),
          Container(
            height: AppSizes.borderWidth,
            color: AppColors.surfaceBorder,
          ),
          InkWell(
            onTap: onAction,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h),
              alignment: Alignment.center,
              child: Text(
                actionLabel,
                style: AppTextStyles.titleSmall.rc(AppColors.link),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
