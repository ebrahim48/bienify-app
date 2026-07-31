import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/test_request.dart';
import '../controllers/results_to_review_controller.dart';
import '../widgets/order_form_fields.dart';

/// What the doctor does about a result: four rows and a Next.
class ChooseReviewOptionScreen extends GetView<ResultsToReviewController> {
  const ChooseReviewOptionScreen({super.key});

  String _label(ReviewOption option) => switch (option) {
    ReviewOption.messagePatient => AppStrings.massagePatient.tr,
    ReviewOption.followUpVisit => AppStrings.requestFollowUpVisit.tr,
    ReviewOption.additionalTest => AppStrings.orderAdditionalTest.tr,
    ReviewOption.refer => AppStrings.referEscalateCare.tr,
  };

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.chooseReviewOption.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          Text(
            AppStrings.chooseYourReviewOption.tr,
            style: AppTextStyles.titleLarge.rw(
              AppColors.gray900,
              FontWeight.w400,
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in ReviewOption.values) ...[
                  OrderChoiceRow(
                    label: _label(option),
                    isSelected: option == controller.reviewOption.value,
                    onTap: () => controller.selectReviewOption(option),
                  ),
                  AppSpacing.gapV(AppSpacing.xs),
                ],
              ],
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          AppButton(
            label: AppStrings.next.tr,
            radius: AppRadius.xl,
            onPressed: controller.confirmReviewOption,
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}
