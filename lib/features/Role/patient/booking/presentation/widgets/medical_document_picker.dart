import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_icons.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';

/// The split Attachment / Camera card under "Medical Document (If any)".
class MedicalDocumentPicker extends StatelessWidget {
  const MedicalDocumentPicker({
    super.key,
    required this.onAttach,
    required this.onCamera,
    this.attachments = const [],
    this.onRemove,
    this.isBusy = false,
  });

  final VoidCallback onAttach;
  final VoidCallback onCamera;
  final List<String> attachments;
  final ValueChanged<String>? onRemove;

  /// True while a pick is uploading — both tiles disable so a second tap
  /// cannot fire mid-upload.
  final bool isBusy;

  static const double _height = 78;

  /// Faded, not hidden — an upload in flight should still read as this card.
  static const double _busyOpacity = 0.4;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          hasShadow: false,
          padding: EdgeInsets.zero,
          // The tiles stay on screen while an upload runs rather than being
          // replaced by a spinner: swapping the whole card out read as the
          // screen having lost its content, and the progress bar says the
          // same thing without taking the labels away.
          child: SizedBox(
            height: _height.h,
            child: Column(
              children: [
                Expanded(
                  child: Opacity(
                    opacity: isBusy ? _busyOpacity : 1,
                    child: Row(
                      children: [
                        Expanded(
                          child: _Tile(
                            icon: AppIcons.cloudUpload,
                            label: AppStrings.attachment.tr,
                            onTap: isBusy ? null : onAttach,
                          ),
                        ),
                        Container(
                          width: AppSizes.borderWidth,
                          color: AppColors.surfaceBorder,
                        ),
                        Expanded(
                          child: _Tile(
                            icon: AppIcons.camera,
                            label: AppStrings.camera.tr,
                            onTap: isBusy ? null : onCamera,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isBusy)
                  LinearProgressIndicator(
                    minHeight: AppSizes.borderWidth * 2,
                    backgroundColor: AppColors.surfaceBorder,
                  ),
              ],
            ),
          ),
        ),
        if (attachments.isNotEmpty) ...[
          AppSpacing.gapV(AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs.w,
            runSpacing: AppSpacing.xs.h,
            children: [
              for (final name in attachments)
                _AttachmentChip(
                  name: name,
                  onRemove: onRemove == null ? null : () => onRemove!(name),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});

  final String icon;
  final String label;

  /// Null while an upload is running, so `InkWell` renders the tile inert
  /// rather than the row merely ignoring the tap.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppSvgIcon(icon, size: AppSizes.xl2, color: AppColors.gray600),
          AppSpacing.gapV(AppSpacing.xs2),
          Text(
            label,
            style: AppTextStyles.bodyMedium.rc(AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({required this.name, this.onRemove});

  final String name;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm.w,
        vertical: AppSpacing.xs2.h + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: AppRadius.rLg,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Flexible, because the name is whatever the patient's file was
          // called and the picker hands back some long ones — a scan straight
          // off a hospital portal overflowed the row by 239px.
          Flexible(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.rc(AppColors.primary700),
            ),
          ),
          if (onRemove != null) ...[
            AppSpacing.gapH(AppSpacing.xs2),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                Icons.close_rounded,
                size: AppSizes.lg.w,
                color: AppColors.primary700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
