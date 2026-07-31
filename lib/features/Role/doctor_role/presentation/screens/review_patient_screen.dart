import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/test_request.dart';
import '../controllers/results_to_review_controller.dart';
import '../widgets/choose_order_sheet.dart';
import '../widgets/patient_row_card.dart';

/// The patient, and the one thing the doctor can do from here.
///
/// Reached two ways, which is the only difference between the designs: from
/// the Patients list it is titled with the patient's name, and from a review
/// it is titled "Order Additional Test". The card and the button are the same.
class ReviewPatientScreen extends GetView<ResultsToReviewController> {
  const ReviewPatientScreen({super.key});

  /// Set when the screen is re-entered from Choose review Option.
  bool get _isAdditional => Get.arguments == ReviewOption.additionalTest;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: Obx(() {
        final patient = controller.patient.value;
        return AppTopBar(
          title: _isAdditional
              ? AppStrings.orderAdditionalTest.tr
              : patient?.name ?? '',
          subtitle: _isAdditional ? null : patient?.ageGenderLine,
        );
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          Obx(() {
            final patient = controller.patient.value;
            return PatientRowCard(
              name: patient?.name ?? '',
              subtitle: patient?.complaint ?? '',
              dateLabel: patient?.seenOnLabel ?? '',
              photoAsset: patient?.photoAsset,
            );
          }),
          AppSpacing.gapV(AppSpacing.sm),
          AppButton(
            label: AppStrings.requestTest.tr,
            radius: AppRadius.xl,
            icon: Icon(
              Icons.add_rounded,
              size: AppSizes.xl2.w,
              color: AppColors.actionLabel,
            ),
            onPressed: () => _chooseOrder(context),
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }

  Future<void> _chooseOrder(BuildContext context) async {
    final kind = await ChooseOrderSheet.show(context);
    if (kind == null) return;
    await Get.toNamed<void>(AppRoutes.doctorRequestTest, arguments: kind);
  }
}
