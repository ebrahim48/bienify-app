import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/app_tag.dart';
import '../../domain/entities/lab_request.dart';

/// The lab-order card at the top of the feed: category and priority tags, a
/// status pill, the test name, who ordered it, and a full-width review action
/// under a rule.
class LabRequestCard extends StatelessWidget {
  const LabRequestCard({
    super.key,
    required this.request,
    required this.onReview,
  });

  final LabRequest request;
  final VoidCallback onReview;

  (String, AppTagTone) get _status => switch (request.status) {
    LabRequestStatus.requestSent => (
      AppStrings.statusRequestSent,
      AppTagTone.pending,
    ),
    LabRequestStatus.inProgress => (
      AppStrings.statusInProgress,
      AppTagTone.info,
    ),
    LabRequestStatus.ready => (AppStrings.statusReady, AppTagTone.success),
  };

  @override
  Widget build(BuildContext context) {
    final (statusKey, statusTone) = _status;

    return AppCard(
      padding: EdgeInsets.all(AppSpacing.base.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The two category tags yield before the status does: on a narrow
          // screen, or with enlarged text, their labels ellipsize instead of
          // the row overflowing.
          Row(
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: AppTag(request.category, tone: AppTagTone.info),
                    ),
                    AppSpacing.gapH(AppSpacing.xs),
                    Flexible(child: AppTag(request.priority)),
                  ],
                ),
              ),
              AppSpacing.gapH(AppSpacing.xs),
              AppTag(statusKey.tr, tone: statusTone),
            ],
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Text(
            request.title,
            style: AppTextStyles.titleMedium.rw(
              AppColors.black,
              FontWeight.w400,
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs2),
          Text(
            AppStrings.requestedBy.trParams({'doctor': request.requestedBy}),
            style: AppTextStyles.bodyLarge.rc(AppColors.textSecondary),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Divider(
            height: AppSizes.borderWidth,
            thickness: AppSizes.borderWidth,
            color: AppColors.surfaceBorder,
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onReview,
              child: Text(
                AppStrings.reviewRequest.tr,
                style: AppTextStyles.titleMedium.rc(AppColors.link),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
