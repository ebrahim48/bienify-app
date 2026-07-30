import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_tag.dart';
import '../../../../core/widgets/app_top_bar.dart';
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
                _FollowUpPanel(
                  doctor: controller.doctorName,
                  // Only the offer state carries the call button; the others
                  // show the panel as a heading over their own section.
                  onAccept: controller.outcome.value ==
                          ReviewOutcome.followUpOffered
                      ? controller.acceptFollowUp
                      : null,
                ),
                if (noteLabel != null) ...[
                  AppSpacing.gapV(AppSpacing.base),
                  _NoteSection(
                    label: noteLabel,
                    onChanged: (value) => controller.replyNote.value = value,
                  ),
                ],
                if (controller.hasRequest) ...[
                  AppSpacing.gapV(AppSpacing.base),
                  _RequestCard(request: controller.request),
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
          Text(
            category,
            style: AppTextStyles.bodyLarge.rc(AppColors.link),
          ),
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
            Text(
              note,
              style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
            ),
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
              'doctor': doctor.replaceFirst('Dr. ', ''),
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

/// A labelled free-text box the patient writes back into — the design's
/// "Message" and "Refer & Escalation" sections, which differ only in heading.
class _NoteSection extends StatelessWidget {
  const _NoteSection({required this.label, required this.onChanged});

  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
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
          // No controller passed: the field owns its own, so nothing is
          // disposed out from under it when the route pops.
          child: TextField(
            onChanged: onChanged,
            maxLines: 3,
            minLines: 3,
            cursorColor: AppColors.primary800,
            style: AppTextStyles.bodyLarge.rc(AppColors.authInk),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: AppStrings.reasonForTestHint.tr,
              hintStyle: AppTextStyles.bodyLarge.rc(AppColors.fieldHint),
            ),
          ),
        ),
      ],
    );
  }
}

/// A further test the doctor ordered: pencil disc, name with a priority tag,
/// the analyte underneath, then the status pill below a hairline.
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final FollowUpRequest request;

  static const double _disc = 40;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: _disc.w,
                height: _disc.w,
                decoration: BoxDecoration(
                  color: AppColors.accentSurface,
                  borderRadius: AppRadius.rLg,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.colorize_rounded,
                  size: AppSizes.xl.w,
                  color: AppColors.actionFill,
                ),
              ),
              AppSpacing.gapH(AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Wrapped so the priority tag drops below a long test
                    // name rather than squeezing it.
                    Wrap(
                      spacing: AppSpacing.xs.w,
                      runSpacing: AppSpacing.xs2.h,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          request.name,
                          style: AppTextStyles.titleSmall.rc(
                            AppColors.gray900,
                          ),
                        ),
                        AppTag(
                          request.priorityLabel,
                          tone: AppTagTone.warning,
                          pill: true,
                        ),
                      ],
                    ),
                    Text(
                      request.detail,
                      style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Container(
            height: AppSizes.borderWidth,
            color: AppColors.surfaceBorder,
          ),
          AppSpacing.gapV(AppSpacing.sm),
          AppTag(
            request.statusLabel,
            tone: AppTagTone.warning,
            hasDot: true,
            pill: true,
          ),
        ],
      ),
    );
  }
}
