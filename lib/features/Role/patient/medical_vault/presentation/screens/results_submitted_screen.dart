import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/status_badge.dart';
import '../controllers/test_results_controller.dart';

/// Confirmation that the report reached the doctor.
///
/// The design has no button: tapping anywhere continues to the review, which
/// is where the patient waits. Reuses `StatusBadge` — the same scalloped seal
/// as the sign-up and booking confirmations, in green.
class ResultsSubmittedScreen extends GetView<TestResultsController> {
  const ResultsSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollable: false,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: controller.viewSubmittedReport,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const StatusBadge(color: AppColors.success500),
            AppSpacing.gapV(AppSpacing.lg),
            Text(
              AppStrings.resultsSubmitted.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium.rc(AppColors.gray900),
            ),
            AppSpacing.gapV(AppSpacing.xs),
            Text(
              AppStrings.resultsSubmittedBody.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.rc(AppColors.gray400),
            ),
          ],
        ),
      ),
    );
  }
}
