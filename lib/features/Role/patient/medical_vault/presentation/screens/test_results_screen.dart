import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/widgets/app_empty_state.dart';
import '../../../../../../core/widgets/app_pill_selector.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/medical_record.dart';
import '../controllers/test_results_controller.dart';
import '../widgets/test_result_card.dart';

/// My tests and results: a discipline toggle, stage filters, and the orders.
class TestResultsScreen extends GetView<TestResultsController> {
  const TestResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.myTestsAndResults.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          // Each `Obx` reads its own observable and hands the children plain
          // values, so the chips repaint when the selection changes.
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
          AppSpacing.gapV(AppSpacing.md),
          Obx(
            () => AppPillSelector(
              labels: [
                for (final value in ResultFilter.values)
                  controller.filterLabel(value),
              ],
              selectedIndex: ResultFilter.values.indexOf(
                controller.filter.value,
              ),
              onSelected: (index) =>
                  controller.selectFilter(ResultFilter.values[index]),
            ),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Obx(() {
            final orders = controller.orders;
            if (orders.isEmpty) {
              return AppEmptyState(
                icon: Icons.science_outlined,
                title: AppStrings.noTestsYet.tr,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final order in orders) ...[
                  TestResultCard(
                    order: order,
                    statusLabel: controller.stageLabel(order.stage),
                    actionLabel: controller.actionLabel(order.stage),
                    onAction: () => controller.openAction(order),
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
