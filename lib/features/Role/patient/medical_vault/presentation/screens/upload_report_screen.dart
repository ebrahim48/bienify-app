import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../controllers/test_results_controller.dart';
import '../widgets/report_thumbnail.dart';

/// Attach the report the patient collected and send it to the doctor.
class UploadReportScreen extends GetView<TestResultsController> {
  const UploadReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.uploadYourReport.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          Obx(() => _Banner(facility: controller.facilityName)),
          AppSpacing.gapV(AppSpacing.base),
          const _NoteLabel(),
          AppSpacing.gapV(AppSpacing.xs),
          // Not `AppTextField`: that is the app's fixed 50pt single-line
          // control, and this is a three-line note. Passing no controller
          // lets the `TextField` own one, so nothing is disposed out from
          // under it when the route pops.
          _NoteField(onChanged: (value) => controller.note.value = value),
          AppSpacing.gapV(AppSpacing.base),
          Text(
            AppStrings.reportDocument.tr,
            style: AppTextStyles.titleMedium.rw(
              AppColors.gray900,
              FontWeight.w400,
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          Obx(
            () => controller.hasDocument.value
                ? ReportThumbnail(
                    onRemove: controller.removeDocument,
                    file: controller.document.value?.file,
                    isImage:
                        controller.document.value?.mime.startsWith('image/') ??
                        true,
                  )
                : _DropZone(onTap: () => controller.attachDocument(context)),
          ),
          AppSpacing.gapV(AppSpacing.base),
          // The button spins while the file is going up, and cannot be
          // pressed again — a second tap used to be free because nothing was
          // actually being uploaded.
          Obx(
            () => AppButton(
              label: AppStrings.uploadAndNotify.tr,
              icon: Icon(
                Icons.send_rounded,
                size: AppSizes.buttonIcon.w,
                color: AppColors.actionLabel,
              ),
              isLoading: controller.uploadProgress.value != null,
              onPressed: controller.upload,
            ),
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.facility});

  final String facility;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.base.w),
      decoration: BoxDecoration(
        color: AppColors.tagInfoSurface,
        borderRadius: AppRadius.rLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.testComplete.tr,
            style: AppTextStyles.titleMedium.rc(AppColors.authInk),
          ),
          AppSpacing.gapV(AppSpacing.xs2),
          Text(
            AppStrings.testCompleteBody.trParams({'facility': facility}),
            style: AppTextStyles.bodyLarge.rc(AppColors.link),
          ),
        ],
      ),
    );
  }
}

/// Three-line note box, styled like the app's inputs.
class _NoteField extends StatelessWidget {
  const _NoteField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm.w,
        vertical: AppSpacing.xs.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: AppRadius.rLg,
        border: Border.all(
          color: AppColors.fieldBorder,
          width: AppSizes.borderWidth,
        ),
      ),
      child: TextField(
        onChanged: onChanged,
        maxLines: 3,
        minLines: 3,
        cursorColor: AppColors.primary800,
        style: AppTextStyles.bodyLarge.rc(AppColors.authInk),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: AppStrings.yourNoteHint.tr,
          hintStyle: AppTextStyles.bodyLarge.rc(AppColors.fieldHint),
        ),
      ),
    );
  }
}

/// `Your note` in ink with `(optional)` trailing it in grey.
class _NoteLabel extends StatelessWidget {
  const _NoteLabel();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: AppStrings.yourNote.tr,
            style: AppTextStyles.titleMedium.rw(
              AppColors.gray900,
              FontWeight.w400,
            ),
          ),
          TextSpan(
            text: AppStrings.optional.tr,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
          ),
        ],
      ),
    );
  }
}

/// Empty attachment slot: a bordered box with an upload glyph.
class _DropZone extends StatelessWidget {
  const _DropZone({required this.onTap});

  final VoidCallback onTap;

  static const double _height = 96;

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
          decoration: BoxDecoration(
            borderRadius: AppRadius.rLg,
            border: Border.all(
              color: AppColors.surfaceBorder,
              width: AppSizes.borderWidth,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.upload_file_outlined,
                size: AppSizes.xl2.w,
                color: AppColors.gray600,
              ),
              AppSpacing.gapV(AppSpacing.xs2),
              Text(
                AppStrings.addReportDocument.tr,
                style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
