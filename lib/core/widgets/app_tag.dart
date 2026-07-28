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

  /// Green — a settled, positive state.
  success,
}

/// Small rounded label used to tag cards.
///
/// ```dart
/// AppTag('Laboratory', tone: AppTagTone.info)
/// AppTag('Request sent', tone: AppTagTone.pending)
/// ```
class AppTag extends StatelessWidget {
  const AppTag(this.label, {super.key, this.tone = AppTagTone.neutral});

  final String label;
  final AppTagTone tone;

  Color get _surface => switch (tone) {
    AppTagTone.info => AppColors.tagInfoSurface,
    AppTagTone.neutral => AppColors.tagNeutralSurface,
    AppTagTone.pending => AppColors.tagPendingSurface,
    AppTagTone.success => AppColors.success50,
  };

  Color get _ink => switch (tone) {
    AppTagTone.info => AppColors.tagInfoInk,
    AppTagTone.neutral => AppColors.tagNeutralInk,
    AppTagTone.pending => AppColors.tagPendingInk,
    AppTagTone.success => AppColors.success700,
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
        borderRadius: AppRadius.rLg,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.labelLarge.rc(_ink),
      ),
    );
  }
}
