import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../constants/app_strings.dart';
import '../services/photo_picker_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

/// Asks where a photo should come from, then returns it.
///
/// A sheet rather than a dialog because it is a two-way choice at the foot of
/// the screen, which is where both platforms put this.
Future<File?> pickPhoto(BuildContext context) async {
  final source = await showModalBottomSheet<PhotoSource>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: AppRadius.rXl2.topLeft),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSpacing.gapV(AppSpacing.sm),
          _SourceRow(
            icon: Icons.photo_camera_outlined,
            label: AppStrings.takeAPhoto.tr,
            onTap: () => Navigator.of(sheetContext).pop(PhotoSource.camera),
          ),
          _SourceRow(
            icon: Icons.photo_library_outlined,
            label: AppStrings.chooseFromGallery.tr,
            onTap: () => Navigator.of(sheetContext).pop(PhotoSource.gallery),
          ),
          AppSpacing.gapV(AppSpacing.sm),
        ],
      ),
    ),
  );

  if (source == null) return null;
  return Get.find<PhotoPickerService>().pick(source);
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.base.w,
          vertical: AppSpacing.sm.h,
        ),
        child: Row(
          children: [
            Icon(icon, size: AppSizes.xl2.w, color: AppColors.authInk),
            AppSpacing.gapH(AppSpacing.sm),
            Text(label, style: AppTextStyles.bodyLarge.rc(AppColors.gray900)),
          ],
        ),
      ),
    );
  }
}

/// A grey dashed tile that takes a photo and then shows it.
///
/// The rider's designs draw this five times over — the selfie, both sides of
/// the ID card, the licence and the vehicle — so it is one widget, sized by
/// the caller. Once a photo is taken the tile becomes the photo, with a
/// small button to replace it.
///
/// ```dart
/// PhotoUploadBox(
///   height: 150,
///   label: AppStrings.takeSelfie.tr,
///   icon: Icons.photo_camera_outlined,
///   file: controller.selfie.value,
///   onPicked: (file) => controller.selfie.value = file,
/// )
/// ```
class PhotoUploadBox extends StatelessWidget {
  const PhotoUploadBox({
    super.key,
    required this.label,
    required this.onPicked,
    this.file,
    this.icon = Icons.add_rounded,
    this.height = 128,
  });

  final String label;

  /// Fired with the captured photo, or not at all if the user backs out.
  final ValueChanged<File> onPicked;

  /// What has been captured so far.
  final File? file;

  final IconData icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final picked = await pickPhoto(context);
        if (picked != null) onPicked(picked);
      },
      child: SizedBox(
        height: height.h,
        child: file == null ? _Empty(icon: icon, label: label) : _Filled(file!),
      ),
    );
  }
}

/// The grey tile with its dashed outline, before anything is taken.
class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.uploadSurface,
        borderRadius: AppRadius.rLg,
      ),
      child: CustomPaint(
        painter: _DashedOutline(radius: AppRadius.lg.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppSizes.xl2.w, color: AppColors.gray800),
            AppSpacing.gapV(AppSpacing.xs2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
            ),
          ],
        ),
      ),
    );
  }
}

/// The photo itself, with the affordance to swap it.
class _Filled extends StatelessWidget {
  const _Filled(this.file);

  final File file;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: AppRadius.rLg,
          child: Image.file(file, fit: BoxFit.cover),
        ),
        Positioned(
          right: AppSpacing.xs.w,
          bottom: AppSpacing.xs.h,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xs.w,
              vertical: AppSpacing.xxs.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.gray900.withValues(alpha: 0.6),
              borderRadius: AppRadius.rFull,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  size: AppSizes.base.w,
                  color: AppColors.white,
                ),
                AppSpacing.gapH(AppSpacing.xs2),
                Text(
                  AppStrings.replacePhoto.tr,
                  style: AppTextStyles.labelMedium.rc(AppColors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Dashed rounded outline. Flutter has no dashed `Border`, and walking the
/// path is cheaper than a package for one rectangle.
class _DashedOutline extends CustomPainter {
  _DashedOutline({required this.radius});

  final double radius;

  static const double _dash = 6;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gray400
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
  bool shouldRepaint(covariant _DashedOutline oldDelegate) => false;
}
