import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/test_request.dart';
import '../controllers/results_to_review_controller.dart';
import '../widgets/order_form_fields.dart';

/// A note to the patient — either a message about the result or a referral.
///
/// One screen for both: the designs are identical apart from the title, the
/// label and the placeholder, so the option chosen decides those three.
class ReviewMessageScreen extends GetView<ResultsToReviewController> {
  const ReviewMessageScreen({super.key});

  bool get _isReferral => Get.arguments == ReviewOption.refer;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(
        title: _isReferral
            ? AppStrings.referEscalation.tr
            : AppStrings.writeMessage.tr,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          OrderFieldLabel(
            _isReferral
                ? AppStrings.writeYourOption.tr
                : AppStrings.writeYourMessage.tr,
          ),
          OrderNoteField(
            hint: _isReferral
                ? AppStrings.referOptionHint.tr
                : AppStrings.reasonForTestHint.tr,
            onChanged: (value) => _isReferral
                ? controller.referralBody.value = value
                : controller.messageBody.value = value,
          ),
          AppSpacing.gapV(AppSpacing.base),
          AppButton(
            label: AppStrings.submitPatients.tr,
            radius: AppRadius.xl,
            onPressed: _submit,
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }

  /// Back to Results to Review rather than through the review options again.
  /// `isFirst` is the safety net: a predicate that never matches would empty
  /// the whole stack.
  void _submit() {
    AppSnackbar.success(AppStrings.sentToPatient.tr);
    Get.until(
      (route) =>
          route.settings.name == AppRoutes.doctorResultsToReview ||
          route.isFirst,
    );
  }
}
