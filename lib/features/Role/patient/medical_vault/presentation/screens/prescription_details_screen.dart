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
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_tag.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/medical_record.dart';
import '../controllers/documents_controller.dart';

/// A single digital prescription, with its medications and a download link.
class PrescriptionDetailsScreen extends GetView<DocumentsController> {
  const PrescriptionDetailsScreen({super.key});

  /// The script that was opened, or null on a deep link that carried none.
  ///
  /// It used to fall back to the design's sample: a real patient opening a
  /// prescription without an argument was shown medications, doses and a
  /// prescribing doctor that had nothing to do with them.
  DigitalPrescription? get _prescription =>
      Get.arguments is DigitalPrescription
      ? Get.arguments as DigitalPrescription
      : null;

  @override
  Widget build(BuildContext context) {
    final prescription = _prescription;
    if (prescription == null) return const SizedBox.shrink();

    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.prescriptionDetails.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          AppCard(
            hasShadow: false,
            padding: EdgeInsets.all(AppSpacing.base.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _Heading(prescription: prescription),
                AppSpacing.gapV(AppSpacing.base),
                const _Divider(),
                AppSpacing.gapV(AppSpacing.base),
                Text(
                  AppStrings.prescribedBy.tr,
                  style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
                ),
                AppSpacing.gapV(AppSpacing.xs),
                Text(
                  prescription.doctorName,
                  style: AppTextStyles.titleMedium.rc(AppColors.gray900),
                ),
                Text(
                  prescription.specialty,
                  style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
                ),
                AppSpacing.gapV(AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: AppSizes.lg.w,
                      color: AppColors.gray500,
                    ),
                    AppSpacing.gapH(AppSpacing.xs2),
                    Text(
                      controller.issuedLabel(prescription.issuedOn),
                      style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
                    ),
                  ],
                ),
                AppSpacing.gapV(AppSpacing.base),
                _DiagnosisPanel(diagnosis: prescription.diagnosis),
                AppSpacing.gapV(AppSpacing.base),
                Text(
                  AppStrings.medications.tr,
                  style: AppTextStyles.titleMedium.rc(AppColors.gray900),
                ),
                AppSpacing.gapV(AppSpacing.sm),
                for (final medication in prescription.medications) ...[
                  _MedicationCard(medication: medication),
                  AppSpacing.gapV(AppSpacing.sm),
                ],
              ],
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          // A digital prescription is rows on the server, not a stored file,
          // so this renders the PDF on the device and hands it to the OS.
          // The card used to print a snackbar and save nothing.
          Obx(
            () => _DownloadCard(
              isBusy: controller.isDownloading.value,
              onTap: () => controller.downloadPrescription(prescription),
            ),
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.prescription});

  final DigitalPrescription prescription;

  static const double _disc = 44;

  @override
  Widget build(BuildContext context) {
    final isActive = prescription.state == PrescriptionState.active;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _disc.w,
          height: _disc.w,
          decoration: const BoxDecoration(
            color: AppColors.tagInfoSurface,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.description_outlined,
            size: AppSizes.xl2.w,
            color: AppColors.link,
          ),
        ),
        AppSpacing.gapH(AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Scaled, not ellipsized: "Digital Prescription" is the name of
              // the document and clipping it to "Digital Prescripti…" reads
              // as a bug.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  AppStrings.digitalPrescription.tr,
                  maxLines: 1,
                  style: AppTextStyles.titleLarge.rc(AppColors.gray900),
                ),
              ),
              Text(
                AppStrings.prescriptionId.trParams({
                  'reference': prescription.reference,
                }),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
              ),
            ],
          ),
        ),
        AppSpacing.gapH(AppSpacing.xs),
        AppTag(
          isActive ? AppStrings.active.tr : AppStrings.expired.tr,
          tone: isActive ? AppTagTone.success : AppTagTone.warning,
          pill: true,
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      Container(height: AppSizes.borderWidth, color: AppColors.surfaceBorder);
}

class _DiagnosisPanel extends StatelessWidget {
  const _DiagnosisPanel({required this.diagnosis});

  final String diagnosis;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      decoration: BoxDecoration(
        color: AppColors.authPanelSoft,
        borderRadius: AppRadius.rLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.diagnosis.tr,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
          ),
          AppSpacing.gapV(AppSpacing.xs2),
          Text(
            diagnosis,
            style: AppTextStyles.titleMedium.rw(
              AppColors.gray900,
              FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// One medication: name and duration on the first row, then the three
/// `Label: value` lines.
class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.medication});

  final Medication medication;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm.w),
      decoration: BoxDecoration(
        borderRadius: AppRadius.rLg,
        border: Border.all(
          color: AppColors.surfaceBorder,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  medication.name,
                  style: AppTextStyles.titleMedium.rw(
                    AppColors.gray900,
                    FontWeight.w400,
                  ),
                ),
              ),
              AppSpacing.gapH(AppSpacing.xs),
              _DurationPill(label: medication.durationLabel),
            ],
          ),
          AppSpacing.gapV(AppSpacing.xs),
          _Detail(label: AppStrings.dosageLabel.tr, value: medication.dosage),
          _Detail(
            label: AppStrings.frequencyLabel.tr,
            value: medication.frequency,
          ),
          // Notes are optional on the prescribing form, so most lines have
          // none. Printing a bare "Instructions:" with nothing after it reads
          // as a line that failed to load.
          if (medication.instructions.isNotEmpty)
            _Detail(
              label: AppStrings.instructionsLabel.tr,
              value: medication.instructions,
            ),
        ],
      ),
    );
  }
}

class _DurationPill extends StatelessWidget {
  const _DurationPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs.w,
        vertical: AppSpacing.xxs.h,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.rFull,
        border: Border.all(
          color: AppColors.surfaceBorder,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Text(label, style: AppTextStyles.bodyMedium.rc(AppColors.gray900)),
    );
  }
}

/// `Dosage: 1 capsule` — the label is bold, the value is not. A single
/// `Text.rich` rather than a `Row` so the value wraps under the label.
class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xxs.h),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: AppTextStyles.bodyLarge.rw(
                AppColors.gray900,
                FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadCard extends StatelessWidget {
  const _DownloadCard({required this.onTap, required this.isBusy});

  final VoidCallback onTap;

  /// While a PDF is being written the card must not read as idle, or a second
  /// tap starts a render the first one is still doing.
  final bool isBusy;

  static const double _spinner = 20;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      onTap: isBusy ? null : onTap,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.base.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isBusy)
            SizedBox(
              width: _spinner.w,
              height: _spinner.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.link,
              ),
            )
          else
            Icon(
              Icons.download_rounded,
              size: AppSizes.xl.w,
              color: AppColors.link,
            ),
          AppSpacing.gapV(AppSpacing.xs2),
          Text(
            AppStrings.downloadPrescription.tr,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
          ),
        ],
      ),
    );
  }
}
