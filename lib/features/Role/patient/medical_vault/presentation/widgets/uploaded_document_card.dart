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
import '../../domain/entities/medical_record.dart';

/// An uploaded file: grey thumbnail, name, kind tag, date, then View and a
/// destructive remove button.
///
/// Shared by the patient's All Prescriptions and the doctor's Appointment
/// Details — the two designs draw the identical card, so it is one widget.
class UploadedDocumentCard extends StatelessWidget {
  const UploadedDocumentCard({
    super.key,
    required this.document,
    required this.dateLabel,
    required this.onView,
    this.onRemove,
  });

  final UploadedDocument document;
  final String dateLabel;
  final VoidCallback onView;

  /// Omitted where the file is not the viewer's to delete.
  final VoidCallback? onRemove;

  static const double _thumb = 52;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _thumb.w,
            height: _thumb.w,
            decoration: BoxDecoration(
              color: AppColors.fileSurface,
              borderRadius: AppRadius.rLg,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.image_outlined,
              size: AppSizes.xl2.w,
              color: AppColors.fileAccent,
            ),
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  document.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.rw(
                    AppColors.gray900,
                    FontWeight.w400,
                  ),
                ),
                AppSpacing.gapV(AppSpacing.xs2),
                _KindTag(label: document.kindLabel),
                AppSpacing.gapV(AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: AppSizes.lg.w,
                      color: AppColors.gray600,
                    ),
                    AppSpacing.gapH(AppSpacing.xs2),
                    Text(
                      dateLabel,
                      style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
                    ),
                  ],
                ),
                AppSpacing.gapV(AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedAction(
                        icon: const Icon(Icons.visibility_outlined),
                        label: AppStrings.view.tr,
                        onTap: onView,
                      ),
                    ),
                    if (onRemove != null) ...[
                      AppSpacing.gapH(AppSpacing.xs),
                      OutlinedAction(
                        // Untinted: the file ships stroked in `logoutFill`.
                        icon: AppSvgIcon(AppIcons.delete, size: AppSizes.xl),
                        onTap: onRemove!,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KindTag extends StatelessWidget {
  const _KindTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs.w,
        vertical: AppSpacing.xxs.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.fileAccentSurface,
        borderRadius: AppRadius.rFull,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelLarge.rc(AppColors.fileAccent),
      ),
    );
  }
}

/// Hairline-outlined button: with a label for View, icon-only for remove.
///
/// [icon] is a widget rather than an `IconData` so a caller can pass an
/// `AppSvgIcon` — the bin is a bundled file, not a Material glyph.
class OutlinedAction extends StatelessWidget {
  const OutlinedAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.label,
    this.ink = AppColors.gray900,
  });

  final Widget icon;
  final VoidCallback onTap;
  final String? label;
  final Color ink;

  static const double height = 36;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.rLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: height.h,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
          decoration: BoxDecoration(
            borderRadius: AppRadius.rLg,
            border: Border.all(
              color: AppColors.surfaceBorder,
              width: AppSizes.borderWidth,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme(
                data: IconThemeData(color: ink, size: AppSizes.xl.w),
                child: icon,
              ),
              if (label != null) ...[
                AppSpacing.gapH(AppSpacing.xs),
                Text(label!, style: AppTextStyles.bodyLarge.rc(ink)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
