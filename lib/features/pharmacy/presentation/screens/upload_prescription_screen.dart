import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../controllers/prescription_controller.dart';

/// Prescription upload: a dashed drop zone over a white card.
class UploadPrescriptionScreen extends GetView<PrescriptionController> {
  const UploadPrescriptionScreen({super.key});

  static const double _zoneHeight = 260;
  static const double _iconBox = 56;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.uploadPrescription.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          CustomPaint(
            painter: _DashedBorderPainter(),
            child: Container(
              height: _zoneHeight.h,
              margin: EdgeInsets.all(AppSpacing.xs2.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.rXl,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: _iconBox.w,
                    height: _iconBox.w,
                    decoration: BoxDecoration(
                      color: AppColors.chatFieldFill,
                      borderRadius: AppRadius.rXl,
                    ),
                    alignment: Alignment.center,
                    child: AppSvgIcon(
                      AppIcons.cloudUpload,
                      size: AppSizes.xl2,
                      color: AppColors.gray500,
                    ),
                  ),
                  AppSpacing.gapV(AppSpacing.base),
                  Text(
                    AppStrings.dropPrescriptionHere.tr,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleMedium.rc(AppColors.gray900),
                  ),
                  AppSpacing.gapV(AppSpacing.xs2),
                  Text(
                    AppStrings.prescriptionFileTypes.tr,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.rc(AppColors.gray400),
                  ),
                  AppSpacing.gapV(AppSpacing.base),
                  _BrowseButton(onTap: controller.browseFile),
                ],
              ),
            ),
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

class _BrowseButton extends StatelessWidget {
  const _BrowseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.actionFill,
      borderRadius: AppRadius.rFull,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg.w,
            vertical: AppSpacing.sm.h,
          ),
          child: Text(
            AppStrings.browseFile.tr,
            style: AppTextStyles.titleSmall.rc(AppColors.actionLabel),
          ),
        ),
      ),
    );
  }
}

/// Dashed outline around the drop zone.
///
/// Painted because Flutter's `Border` has no dashed style, and the design's
/// dashes read as "drop a file here" in a way a solid rule does not.
class _DashedBorderPainter extends CustomPainter {
  static const double _dash = 6;
  static const double _gap = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gray300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(AppRadius.xl),
        ),
      );

    for (final metric in outline.computeMetrics()) {
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
