import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/services/attachment_picker_service.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';

/// What to attach, asked before the picker opens.
///
/// A sheet rather than a menu because the four sources are equal choices with
/// their own icons — and because the paperclip used to do exactly one thing,
/// which meant sending a photo and sending a PDF were the same button.
class AttachmentSheet extends StatelessWidget {
  const AttachmentSheet({super.key});

  /// Resolves to the chosen source, or null if dismissed.
  static Future<AttachmentSource?> show(BuildContext context) =>
      showModalBottomSheet<AttachmentSource>(
        context: context,
        backgroundColor: AppColors.transparent,
        builder: (_) => const AttachmentSheet(),
      );

  static const List<(AttachmentSource, IconData, String)> _options = [
    (AttachmentSource.camera, Icons.photo_camera_rounded, AppStrings.attachCamera),
    (AttachmentSource.gallery, Icons.image_rounded, AppStrings.attachPhoto),
    (AttachmentSource.video, Icons.videocam_rounded, AppStrings.attachVideo),
    (
      AttachmentSource.document,
      Icons.insert_drive_file_rounded,
      AppStrings.attachDocument,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.all(AppSpacing.sm.w),
        padding: EdgeInsets.symmetric(vertical: AppSpacing.base.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.rXl,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final (source, icon, label) in _options)
              _Option(
                icon: icon,
                label: label.tr,
                onTap: () => Navigator.of(context).pop(source),
              ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  static const double _tile = 56;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: _tile.r,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _tile.w,
              height: _tile.w,
              decoration: const BoxDecoration(
                color: AppColors.accentSurface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: AppSizes.xl2.w, color: AppColors.primary600),
            ),
            AppSpacing.gapV(AppSpacing.xs),
            Text(label, style: AppTextStyles.bodyMedium.rc(AppColors.gray600)),
          ],
        ),
      ),
    );
  }
}
