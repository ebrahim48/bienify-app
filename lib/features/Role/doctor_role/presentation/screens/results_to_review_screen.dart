import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_pill_selector.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/app_top_bar.dart';
import '../../../patient/doctors/presentation/widgets/doctor_search_field.dart';
import '../../domain/entities/test_request.dart';
import '../controllers/results_to_review_controller.dart';
import '../widgets/patient_row_card.dart';
import '../widgets/request_status_card.dart';

/// Results to Review — one screen behind three segments.
///
/// Patients searches the roster; the other two list that department's orders
/// under a filter row. The designs draw the same page three times over, so it
/// is one screen and the segment decides what fills it.
class ResultsToReviewScreen extends GetView<ResultsToReviewController> {
  const ResultsToReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.resultsToReview.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.xs),
          Obx(
            () => AppPillSelector(
              labels: [
                for (final value in ResultsTab.values)
                  controller.tabLabel(value),
              ],
              selectedIndex: ResultsTab.values.indexOf(controller.tab.value),
              onSelected: (index) =>
                  controller.selectTab(ResultsTab.values[index]),
              isLarge: true,
              // The design's tighter inset; at the usual 16 the third
              // segment falls off a 390pt frame.
              horizontalPadding: AppSpacing.sm,
            ),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Obx(
            () => controller.tab.value == ResultsTab.patients
                ? const _PatientsPane()
                : const _RequestsPane(),
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

/// Search box, heading, then the roster.
class _PatientsPane extends GetView<ResultsToReviewController> {
  const _PatientsPane();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // The field owns its controller; the screen only listens.
        DoctorSearchField(
          initialText: controller.query.value,
          hintKey: AppStrings.searchPatientName,
          onChanged: (value) => controller.query.value = value,
        ),
        AppSpacing.gapV(AppSpacing.sm),
        Text(
          AppStrings.patientsTab.tr,
          style: AppTextStyles.titleMedium.rw(
            AppColors.gray900,
            FontWeight.w400,
          ),
        ),
        AppSpacing.gapV(AppSpacing.xs),
        Obx(() {
          final rows = controller.visiblePatients;
          if (rows.isEmpty) {
            return AppEmptyState(title: AppStrings.noTestsYet.tr);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final patient in rows) ...[
                PatientRowCard(
                  name: patient.name,
                  subtitle: patient.code,
                  dateLabel: patient.seenOnLabel,
                  photoAsset: patient.photoAsset,
                  onTap: () => controller.openPatient(patient),
                ),
                AppSpacing.gapV(AppSpacing.xs),
              ],
            ],
          );
        }),
      ],
    );
  }
}

/// Filter chips, then that department's orders.
class _RequestsPane extends GetView<ResultsToReviewController> {
  const _RequestsPane();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // A tone below the segments above them: the design fills the
        // unselected chips slate rather than outlining them in white.
        Obx(
          () => AppPillSelector(
            labels: [
              for (final value in RequestFilter.values)
                controller.filterLabel(value),
            ],
            selectedIndex: RequestFilter.values.indexOf(
              controller.filter.value,
            ),
            onSelected: (index) =>
                controller.selectFilter(RequestFilter.values[index]),
            unselectedFill: AppColors.chipSurface,
            unselectedInk: AppColors.chipInk,
            unselectedBorder: AppColors.transparent,
          ),
        ),
        AppSpacing.gapV(AppSpacing.sm),
        Obx(() {
          final rows = controller.visibleRequests;
          if (rows.isEmpty) {
            return AppEmptyState(title: AppStrings.noRequestsYet.tr);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final request in rows) ...[
                RequestStatusCard(
                  request: request,
                  onTap: () => controller.openRequest(request),
                ),
                AppSpacing.gapV(AppSpacing.sm),
              ],
            ],
          );
        }),
      ],
    );
  }
}
