import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_tag.dart';
import '../../domain/entities/test_request.dart';

/// A lab or radiology request: the order above a hairline, its state below.
class RequestStatusCard extends StatelessWidget {
  const RequestStatusCard({
    super.key,
    required this.request,
    required this.onTap,
  });

  final TestRequest request;
  final VoidCallback onTap;

  static const double _tile = 48;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      hasShadow: false,
      borderColor: AppColors.transparent,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.base.w),
            child: Row(
              children: [
                _Glyph(kind: request.kind),
                AppSpacing.gapH(AppSpacing.sm),
                Expanded(child: _Titles(request: request)),
                AppSpacing.gapH(AppSpacing.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  size: AppSizes.xl2.w,
                  color: AppColors.gray600,
                ),
              ],
            ),
          ),
          Divider(
            height: AppSizes.borderWidth,
            thickness: AppSizes.borderWidth,
            color: AppColors.chipSurface,
          ),
          Padding(
            padding: EdgeInsets.all(AppSpacing.base.w),
            child: Row(
              children: [
                _StatusPill(status: request.status),
                if (request.isCritical) ...[
                  AppSpacing.gapH(AppSpacing.xs),
                  const _CriticalPill(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pale-blue tile with the department's glyph in it.
class _Glyph extends StatelessWidget {
  const _Glyph({required this.kind});

  final OrderKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: RequestStatusCard._tile.w,
      height: RequestStatusCard._tile.w,
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: AppRadius.rXl,
      ),
      alignment: Alignment.center,
      child: Icon(
        kind == OrderKind.lab
            ? Icons.science_outlined
            : Icons.monitor_heart_outlined,
        size: AppSizes.xl2.w,
        color: AppColors.actionFill,
      ),
    );
  }
}

class _Titles extends StatelessWidget {
  const _Titles({required this.request});

  final TestRequest request;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // The title and its priority sit on one line but the title is the
        // one that gives way, so the pill is never clipped.
        Row(
          children: [
            Flexible(
              child: Text(
                request.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium.rc(AppColors.gray900),
              ),
            ),
            AppSpacing.gapH(AppSpacing.xs),
            _PriorityPill(priority: request.priority),
          ],
        ),
        AppSpacing.gapV(AppSpacing.xs2),
        Text(
          request.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
        ),
      ],
    );
  }
}

/// Routine orders carry no pill in the designs — only the ones that need
/// hurrying are called out.
class _PriorityPill extends StatelessWidget {
  const _PriorityPill({required this.priority});

  final OrderPriority priority;

  @override
  Widget build(BuildContext context) {
    if (priority == OrderPriority.routine) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm.w,
        vertical: AppSpacing.xs2.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.urgentSurface,
        borderRadius: AppRadius.rLg,
      ),
      child: Text(
        priority == OrderPriority.urgent
            ? AppStrings.priorityUrgent.tr
            : AppStrings.priorityStat.tr,
        style: AppTextStyles.bodyLarge.rc(AppColors.urgentInk),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (status) {
      RequestStatus.requestSent => (
        AppStrings.requestSent.tr,
        AppTagTone.pending,
      ),
      RequestStatus.awaitingReview => (
        AppStrings.awaitingReview.tr,
        AppTagTone.warning,
      ),
      RequestStatus.reviewed => (AppStrings.reviewed.tr, AppTagTone.success),
    };

    return AppTag(label, tone: tone, hasDot: true, pill: true);
  }
}

/// The one filled-red pill in the app; [AppTag] has no tone this loud.
class _CriticalPill extends StatelessWidget {
  const _CriticalPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm.w,
        vertical: AppSpacing.xs2.h + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.criticalSurface,
        borderRadius: AppRadius.rFull,
      ),
      child: Text(
        AppStrings.critical.tr,
        style: AppTextStyles.labelLarge.rc(AppColors.white),
      ),
    );
  }
}
