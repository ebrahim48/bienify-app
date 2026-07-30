import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';

/// The attached report, with a remove button in its top-right corner.
///
/// `report.png` ships with a close button drawn into the artwork, so the real
/// one is placed over it at the same inset — otherwise the page would show
/// two, one of them dead.
class ReportThumbnail extends StatelessWidget {
  const ReportThumbnail({super.key, this.onRemove});

  /// Omitted on the review screen, where the report is no longer the
  /// patient's to withdraw.
  final VoidCallback? onRemove;

  static const double height = 146;
  static const double _button = 28;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: AppRadius.rLg,
          child: SizedBox(
            width: double.infinity,
            height: height.h,
            child: Image.asset(AppAssets.reportDocument, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: AppSpacing.xs.h,
          right: AppSpacing.xs.w,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRemove,
            child: Container(
              width: _button.w,
              height: _button.w,
              decoration: BoxDecoration(
                color: AppColors.gray800.withValues(alpha: 0.72),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.close_rounded,
                size: AppSizes.lg.w,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
