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
import '../../domain/entities/medical_record.dart';
import '../controllers/test_results_controller.dart';
import '../widgets/report_thumbnail.dart';

/// The uploaded report and where it stands with the doctor.
///
/// Five states in one screen, which is how the designs differ: while the
/// doctor has it, an orange note; afterwards the "Choose the Next Step" panel,
/// then either a call button, a Message or Refer & Escalation box, or the
/// further test they ordered.
class ReportReviewScreen extends GetView<TestResultsController> {
  const ReportReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.reportAndDoctorReview.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          Obx(
            () => _Summary(
              category: controller.selected.value?.category ?? '',
              title: controller.selected.value?.title ?? '',
              note: controller.note.value,
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          Text(
            AppStrings.reportDocument.tr,
            style: AppTextStyles.titleMedium.rw(
              AppColors.gray900,
              FontWeight.w400,
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          // No remove action: once it is with the doctor it is no longer the
          // patient's to withdraw.
          const ReportThumbnail(),
          AppSpacing.gapV(AppSpacing.base),
          // The outcome is read here so the footer swaps when it changes. All
          // four post-review states share the "Choose the Next Step" panel;
          // what follows it is what differs.
          Obx(() {
            if (!controller.hasFollowUp) {
              return _WaitingNote(doctor: controller.doctorName);
            }
            final noteLabel = controller.noteSectionLabel;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // "Talk to you" belongs to the one outcome that is an offer to
                // talk. It used to be drawn for every reviewed order, so a
                // doctor who had written a note appeared to be asking for a
                // call they had not asked for.
                if (controller.outcome.value == ReviewOutcome.followUpOffered)
                  _FollowUpPanel(
                    doctor: controller.doctorName,
                    onAccept: controller.acceptFollowUp,
                  ),
                if (noteLabel != null) ...[
                  AppSpacing.gapV(AppSpacing.base),
                  // What the doctor actually wrote. The server sends it, the
                  // app parsed it into `reviewMessage`, and no screen read it
                  // — so every reviewed result reached the patient as an empty
                  // box to type into, with the doctor's words nowhere on the
                  // screen at all.
                  _DoctorNote(
                    label: noteLabel,
                    message: controller.reviewMessage,
                  ),
                ],
              ],
            );
          }),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

/// The blue recap at the top: category, study name, and the patient's own
/// question back to them.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.category,
    required this.title,
    required this.note,
  });

  final String category;
  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      decoration: BoxDecoration(
        color: AppColors.tagInfoSurface,
        borderRadius: AppRadius.rLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(category, style: AppTextStyles.bodyLarge.rc(AppColors.link)),
          AppSpacing.gapV(AppSpacing.xs2),
          Text(
            title,
            style: AppTextStyles.titleMedium.rw(
              AppColors.gray900,
              FontWeight.w400,
            ),
          ),
          if (note.isNotEmpty) ...[
            AppSpacing.gapV(AppSpacing.xs2),
            Text(note, style: AppTextStyles.bodyMedium.rc(AppColors.gray500)),
          ],
        ],
      ),
    );
  }
}

class _WaitingNote extends StatelessWidget {
  const _WaitingNote({required this.doctor});

  final String doctor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      decoration: BoxDecoration(
        color: AppColors.tagWarningSurface,
        borderRadius: AppRadius.rLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.reportIsWith.trParams({'doctor': doctor}),
            style: AppTextStyles.titleMedium.rc(AppColors.tagWarningInk),
          ),
          AppSpacing.gapV(AppSpacing.xxs),
          Text(
            AppStrings.reportIsWithBody.tr,
            style: AppTextStyles.bodyLarge.rc(AppColors.tagWarningInk),
          ),
        ],
      ),
    );
  }
}

class _FollowUpPanel extends StatelessWidget {
  const _FollowUpPanel({required this.doctor, this.onAccept});

  final String doctor;

  /// Omitted when the doctor's outcome is not an offer to talk — the panel
  /// then reads as a heading over whatever section follows it.
  final VoidCallback? onAccept;

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
        children: [
          Text(
            AppStrings.chooseTheNextStep.tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.rc(AppColors.authInk),
          ),
          AppSpacing.gapV(AppSpacing.xs2),
          Text(
            // The doctor's honorific is already in the copy, so the raw name
            // is passed through without it.
            AppStrings.doctorWantsToTalk.trParams({
              'doctor': withoutHonorific(doctor),
            }),
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium.rw(
              AppColors.authInk,
              FontWeight.w400,
            ),
          ),
          if (onAccept != null) ...[
            AppSpacing.gapV(AppSpacing.md),
            AppButton(
              label: AppStrings.acceptFollowUp.tr,
              icon: Icon(
                Icons.phone_in_talk_rounded,
                size: AppSizes.buttonIcon.w,
                color: AppColors.actionLabel,
              ),
              radius: AppRadius.lg,
              onPressed: onAccept,
            ),
          ],
        ],
      ),
    );
  }
}

/// A doctor's name with any honorific taken off it.
///
/// The copy around it already says "Doctor", so the name must not repeat it.
/// The old strip matched `Dr. ` only — with the dot — and every name the
/// server actually sends is `Dr Dana Okafor`, so the panel read
/// "Doctor Dr Dana Okafor".
String withoutHonorific(String name) {
  final trimmed = name.trim();
  for (final prefix in const ['Dr. ', 'Dr ', 'Doctor ']) {
    if (trimmed.startsWith(prefix)) return trimmed.substring(prefix.length);
  }
  return trimmed;
}

/// The doctor's own words, under the heading their outcome names.
///
/// This was a free-text box the patient typed into. Nothing read what they
/// typed — `replyNote` was written by the field and referenced nowhere else,
/// there is no patient-reply endpoint on a lab order, and the order carries no
/// consultation to send into either. So the box collected a reply to a doctor
/// who could never receive it, while the message that doctor had actually sent
/// was not shown anywhere on the screen.
class _DoctorNote extends StatelessWidget {
  const _DoctorNote({required this.label, required this.message});

  final String label;
  final String message;

  @override
  Widget build(BuildContext context) {
    if (message.trim().isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.titleMedium.rw(
            AppColors.gray900,
            FontWeight.w400,
          ),
        ),
        AppSpacing.gapV(AppSpacing.xs),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppSpacing.sm.w),
          decoration: BoxDecoration(
            color: AppColors.fieldFill,
            borderRadius: AppRadius.rLg,
            border: Border.all(
              color: AppColors.fieldBorder,
              width: AppSizes.borderWidth,
            ),
          ),
          child: Text(
            message,
            style: AppTextStyles.bodyLarge.rc(AppColors.authInk),
          ),
        ),
      ],
    );
  }
}

/// A further test the doctor ordered: pencil disc, name with a priority tag,
/// the analyte underneath, then the status pill below a hairline.
