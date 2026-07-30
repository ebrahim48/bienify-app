import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

/// The tone a [AppTag] is drawn in.
enum AppTagTone {
  /// Blue — a category ("Laboratory").
  info,

  /// Slate — a neutral qualifier ("Routine").
  neutral,

  /// Amber — an in-flight state ("Request sent").
  pending,

  /// Green — a settled, positive state ("Reviewed").
  success,

  /// Orange — something is waiting on someone ("Awaiting review").
  warning,
}

/// Small rounded label used to tag cards.
///
/// ```dart
/// AppTag('Laboratory', tone: AppTagTone.info)
/// AppTag('Request sent', tone: AppTagTone.pending)
/// AppTag('Reviewed', tone: AppTagTone.success, hasDot: true, pill: true)
/// ```
class AppTag extends StatelessWidget {
  const AppTag(
    this.label, {
    super.key,
    this.tone = AppTagTone.neutral,
    this.hasDot = false,
    this.pill = false,
  });

  final String label;
  final AppTagTone tone;

  /// Leading dot in the ink colour, as the "Reviewed" status pill carries.
  final bool hasDot;

  /// Fully rounded rather than `lg`. Category tags are rounded rectangles;
  /// status pills in the results list are pills.
  final bool pill;

  static const double _dot = 6;

  Color get _surface => switch (tone) {
    AppTagTone.info => AppColors.tagInfoSurface,
    AppTagTone.neutral => AppColors.tagNeutralSurface,
    AppTagTone.pending => AppColors.tagPendingSurface,
    AppTagTone.success => AppColors.tagSuccessSurface,
    AppTagTone.warning => AppColors.tagWarningSurface,
  };

  Color get _ink => switch (tone) {
    AppTagTone.info => AppColors.tagInfoInk,
    AppTagTone.neutral => AppColors.tagNeutralInk,
    AppTagTone.pending => AppColors.tagPendingInk,
    AppTagTone.success => AppColors.tagSuccessInk,
    AppTagTone.warning => AppColors.tagWarningInk,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm.w,
        vertical: AppSpacing.xs2.h + 2,
      ),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: pill ? AppRadius.rFull : AppRadius.rLg,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasDot) ...[
            Container(
              width: _dot.w,
              height: _dot.w,
              decoration: BoxDecoration(color: _ink, shape: BoxShape.circle),
            ),
            AppSpacing.gapH(AppSpacing.xs2),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelLarge.rc(_ink),
            ),
          ),
        ],
      ),
    );
  }
}
