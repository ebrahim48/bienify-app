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

/// Dashed drop target for a document.
///
/// The practitioner's licence and the shop's licence, logo and banner are the
/// same control four times over, so it is one widget.
class DashedDropZone extends StatelessWidget {
  const DashedDropZone({
    super.key,
    required this.hasFile,
    required this.onTap,
    this.attachedLabel,
  });

  final bool hasFile;
  final VoidCallback onTap;

  /// What to say once something is attached; defaults to the licence wording.
  final String? attachedLabel;

  static const double _height = 116;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: hasFile ? AppColors.actionFill : AppColors.gray300,
          radius: AppRadius.lg.r,
        ),
        child: SizedBox(
          height: _height.h,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasFile
                    ? Icons.check_circle_outline_rounded
                    : Icons.file_upload_outlined,
                size: AppSizes.xl2.w,
                color: hasFile ? AppColors.actionFill : AppColors.gray400,
              ),
              AppSpacing.gapV(AppSpacing.xs),
              Text(
                hasFile
                    ? (attachedLabel ?? AppStrings.licenseAttached.tr)
                    : AppStrings.uploadHint.tr,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
              ),
              AppSpacing.gapV(AppSpacing.xxs),
              Text(
                AppStrings.uploadFileTypes.tr,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.rc(AppColors.gray400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws a dashed rounded rectangle. Flutter has no dashed `Border`, and
/// walking the path is cheaper than shipping a package for one outline.
class DashedBorderPainter extends CustomPainter {
  DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _dash = 6;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
