import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/widgets/app_pill_selector.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/medical_record.dart';
import '../controllers/documents_controller.dart';
import '../widgets/record_row.dart';

/// All Test Reports — a Lab / Radiology toggle over the record list.
///
/// Rows open the existing prescription detail; the design lists the same
/// numbered records under both disciplines.
class AllTestReportsScreen extends GetView<DocumentsController> {
  const AllTestReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.allTestReports.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          Obx(
            () => AppPillSelector(
              labels: [
                for (final value in ResultDiscipline.values)
                  controller.disciplineLabel(value),
              ],
              selectedIndex: ResultDiscipline.values.indexOf(
                controller.discipline.value,
              ),
              onSelected: (index) =>
                  controller.selectDiscipline(ResultDiscipline.values[index]),
              isLarge: true,
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          Obx(() {
            final reports = controller.prescriptions.toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < reports.length; index++) ...[
                  RecordRow(
                    title: controller.numberedLabel(index),
                    subtitle: AppStrings.prescriptionId.trParams({
                      'reference': reports[index].reference,
                    }),
                    onTap: () => controller.openPrescription(reports[index]),
                  ),
                  AppSpacing.gapV(AppSpacing.sm),
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
