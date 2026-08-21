import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';

/// The attached report, with a remove button in its top-right corner.
///
/// `report.png` ships with a close button drawn into the artwork, so the real
/// one is placed over it at the same inset — otherwise the page would show
/// two, one of them dead.
class ReportThumbnail extends StatelessWidget {
  const ReportThumbnail({super.key, this.onRemove, this.file, this.isImage = true});

  /// Omitted on the review screen, where the report is no longer the
  /// patient's to withdraw.
  final VoidCallback? onRemove;

  /// The file the patient actually picked.
  ///
  /// Null on the review screen, which shows a report already submitted and
  /// has no local copy of it. When it is present the patient sees their own
  /// document rather than the bundled artwork — showing stock cover art for
  /// the file someone just chose is how a picker that did nothing managed to
  /// look like one that worked.
  final File? file;

  /// False for a PDF or anything else with no preview to draw, which falls
  /// back to the artwork rather than a broken image.
  final bool isImage;

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
            child: file != null && isImage
                ? Image.file(
                    file!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Image.asset(AppAssets.reportDocument, fit: BoxFit.cover),
                  )
                : Image.asset(AppAssets.reportDocument, fit: BoxFit.cover),
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
