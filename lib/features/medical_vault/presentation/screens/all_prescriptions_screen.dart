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
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_pill_selector.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/medical_record.dart';
import '../controllers/documents_controller.dart';
import '../widgets/record_row.dart';

/// All Prescriptions — the patient's own uploads on one tab, the prescriptions
/// Bienify holds on the other.
class AllPrescriptionsScreen extends GetView<DocumentsController> {
  const AllPrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.allPrescriptions.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          // The selection is read here so the pills repaint; the selector is
          // handed plain values.
          Obx(
            () => AppPillSelector(
              labels: [
                for (final value in PrescriptionSource.values)
                  controller.sourceLabel(value),
              ],
              selectedIndex: PrescriptionSource.values.indexOf(
                controller.source.value,
              ),
              onSelected: (index) => controller.selectSource(
                PrescriptionSource.values[index],
              ),
              isLarge: true,
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          Obx(
            () => controller.source.value == PrescriptionSource.uploads
                ? _Uploads(controller: controller)
                : _Vault(controller: controller),
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

class _Uploads extends StatelessWidget {
  const _Uploads({required this.controller});

  final DocumentsController controller;

  @override
  Widget build(BuildContext context) {
    // `.toList()` materialises the observable inside this `Obx`.
    final uploads = controller.uploads.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (uploads.isEmpty)
          AppEmptyState(
            icon: Icons.upload_file_outlined,
            title: AppStrings.noUploadsYet.tr,
          )
        else
          for (final document in uploads) ...[
            _UploadCard(
              document: document,
              dateLabel: controller.shortDateLabel(document.uploadedOn),
              onView: () => controller.viewUpload(document),
              onRemove: () => controller.removeUpload(document),
            ),
            AppSpacing.gapV(AppSpacing.sm),
          ],
        _UploadButton(onTap: controller.uploadPrescription),
      ],
    );
  }
}

class _Vault extends StatelessWidget {
  const _Vault({required this.controller});

  final DocumentsController controller;

  @override
  Widget build(BuildContext context) {
    final prescriptions = controller.prescriptions.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < prescriptions.length; index++) ...[
          RecordRow(
            title: controller.numberedLabel(index),
            subtitle: AppStrings.prescriptionId.trParams({
              'reference': prescriptions[index].reference,
            }),
            onTap: () => controller.openPrescription(prescriptions[index]),
          ),
          AppSpacing.gapV(AppSpacing.sm),
        ],
      ],
    );
  }
}

/// An uploaded file: grey thumbnail tile, name, kind tag, date, then View and
/// a destructive remove button.
class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.document,
    required this.dateLabel,
    required this.onView,
    required this.onRemove,
  });

  final UploadedDocument document;
  final String dateLabel;
  final VoidCallback onView;
  final VoidCallback onRemove;

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
                      child: _OutlinedAction(
                        icon: Icons.visibility_outlined,
                        label: AppStrings.view.tr,
                        onTap: onView,
                      ),
                    ),
                    AppSpacing.gapH(AppSpacing.xs),
                    _OutlinedAction(
                      icon: Icons.delete_outline_rounded,
                      ink: AppColors.logoutFill,
                      onTap: onRemove,
                    ),
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

/// Hairline-outlined button. Used with a label for View, and icon-only for the
/// remove action beside it.
class _OutlinedAction extends StatelessWidget {
  const _OutlinedAction({
    required this.icon,
    required this.onTap,
    this.label,
    this.ink = AppColors.gray900,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? label;
  final Color ink;

  static const double _height = 36;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.rLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: _height.h,
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
              Icon(icon, size: AppSizes.xl.w, color: ink),
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

/// Small filled action, sized to its label rather than full width — the design
/// puts it under the list, left-aligned.
class _UploadButton extends StatelessWidget {
  const _UploadButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: AppColors.actionFill,
        borderRadius: AppRadius.rLg,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm.w,
              vertical: AppSpacing.xs.h,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSvgIcon(
                  AppIcons.cloudUpload,
                  size: AppSizes.lg,
                  color: AppColors.actionLabel,
                ),
                AppSpacing.gapH(AppSpacing.xs),
                Text(
                  AppStrings.uploadPrescriptionAction.tr,
                  style: AppTextStyles.bodyLarge.rc(AppColors.actionLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
