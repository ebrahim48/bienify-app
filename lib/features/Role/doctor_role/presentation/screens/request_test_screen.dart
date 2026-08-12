import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
import '../../../patient/doctors/presentation/widgets/doctor_search_field.dart';
import '../../data/static/doctor_orders_data.dart';
import '../../domain/entities/test_request.dart';
import '../controllers/test_request_controller.dart';
import '../widgets/order_form_fields.dart';

/// The three-step request wizard, for both kinds of order.
///
/// The designs draw eight screens here; they are the same three steps twice
/// over, so this is one screen and [TestRequestController.kind] decides what
/// each step holds — a lab request takes its notes on step two, an imaging
/// request picks a subtest there and reviews everything on step three.
class RequestTestScreen extends GetView<TestRequestController> {
  const RequestTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(
        title: controller.title,
        subtitle: controller.patient.name,
        // Walks back through the wizard before leaving it.
        onBack: () {
          if (!controller.stepBack()) Get.back<void>();
        },
      ),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.gapV(AppSpacing.xs),
            OrderProgressBar(
              step: controller.step.value,
              stepCount: TestRequestController.stepCount,
            ),
            AppSpacing.gapV(AppSpacing.base),
            if (controller.sectionHeading != null) ...[
              Text(
                controller.sectionHeading!,
                style: AppTextStyles.titleLarge.rw(
                  AppColors.gray900,
                  FontWeight.w400,
                ),
              ),
              AppSpacing.gapV(AppSpacing.sm),
            ],
            ..._step(context),
            AppSpacing.gapV(AppSpacing.base),
            AppButton(
              // One screen serves both kinds, so the submit label has to follow
              // the kind — a lab order used to end on "Submit imaging Order".
              label: controller.isLastStep
                  ? (controller.isRadiology
                        ? AppStrings.submitImagingOrder.tr
                        : AppStrings.submitLabOrder.tr)
                  : AppStrings.next.tr,
              radius: AppRadius.xl,
              isEnabled: controller.canContinue,
              // The design greys a dead Next out rather than fading it.
              disabledFill: AppColors.gray400,
              onPressed: controller.next,
            ),
            AppSpacing.gapV(AppSpacing.md),
          ],
        ),
      ),
    );
  }

  /// What this step holds. Imaging splits the catalogue over two steps and
  /// reviews on the third; laboratory takes its notes on the second.
  List<Widget> _step(BuildContext context) {
    if (controller.step.value == 0) return [const _CataloguePane()];
    if (controller.step.value == 1) {
      return controller.isRadiology
          ? [const _SubtestPane()]
          : [const _NotesPane()];
    }
    return controller.isRadiology
        ? [
            const _PriorityPane(),
            AppSpacing.gapV(AppSpacing.md),
            const _NotesPane(),
          ]
        : [const _PriorityPane()];
  }
}

/// Banner, search box and the department's tests.
class _CataloguePane extends GetView<TestRequestController> {
  const _CataloguePane();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        OrderRequestBanner(
          title: controller.isRadiology
              ? AppStrings.radiologyRequest.tr
              : AppStrings.laboratoryRequest.tr,
          icon: Icons.science_outlined,
        ),
        AppSpacing.gapV(AppSpacing.sm),
        // The field owns its controller; the wizard only listens.
        DoctorSearchField(
          initialText: controller.query.value,
          hintKey: controller.isRadiology
              ? AppStrings.searchRadiologyTest
              : AppStrings.searchLabTest,
          onChanged: (value) => controller.query.value = value,
        ),
        AppSpacing.gapV(AppSpacing.sm),
        Text(
          controller.isRadiology
              ? AppStrings.selectRadiologyTest.tr
              : AppStrings.selectLabTest.tr,
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
              for (final test in controller.visibleTests) ...[
                OrderChoiceRow(
                  label: test,
                  isSelected: test == controller.selectedTest.value,
                  onTap: () => controller.selectTest(test),
                ),
                AppSpacing.gapV(AppSpacing.xs),
              ],
              // Last row of the catalogue: somewhere to name a test that is
              // not on it. Typing into it is what selects it.
              _FreeTextRow(
                hint: controller.isRadiology
                    ? AppStrings.enterTestName.tr
                    : AppStrings.enterNewLabTest.tr,
                onChanged: (value) => controller.selectedTest.value =
                    value.trim().isEmpty ? null : value,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Imaging's second step: the same catalogue again, as its subtests.
class _SubtestPane extends GetView<TestRequestController> {
  const _SubtestPane();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.selectRadiologySubtest.tr,
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
              for (final test in controller.subtests) ...[
                OrderChoiceRow(
                  label: test,
                  isSelected: test == controller.selectedSubtest.value,
                  onTap: () => controller.selectSubtest(test),
                ),
                AppSpacing.gapV(AppSpacing.xs),
              ],
              _FreeTextRow(
                hint: AppStrings.enterTestName.tr,
                onChanged: (value) => controller.selectedSubtest.value =
                    value.trim().isEmpty ? null : value,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Clinical notes, patient instructions and the signature.
class _NotesPane extends GetView<TestRequestController> {
  const _NotesPane();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        OrderFieldLabel(AppStrings.clinicalNotes.tr),
        OrderNoteField(
          hint: AppStrings.reasonForTestHint.tr,
          onChanged: (value) => controller.clinicalNotes.value = value,
        ),
        AppSpacing.gapV(AppSpacing.base),
        OrderFieldLabel(AppStrings.patientsInstructions.tr, isOptional: true),
        OrderNoteField(
          hint: AppStrings.patientsInstructionsHint.tr,
          onChanged: (value) => controller.instructions.value = value,
        ),
        AppSpacing.gapV(AppSpacing.base),
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.xs.h),
          child: Text(
            AppStrings.electricSign.tr,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
          ),
        ),
        // Not wrapped in `Obx`: the pad owns its ink and rebuilding it from
        // an observable would wipe the strokes mid-signature.
        ElectricSignField(
          hint: DoctorOrdersData.signatureHint,
          onChanged: controller.signed,
          onSave: controller.saveSignature,
        ),
      ],
    );
  }
}

/// The three urgency cards.
class _PriorityPane extends GetView<TestRequestController> {
  const _PriorityPane();

  static const Map<OrderPriority, IconData> _icons = {
    OrderPriority.routine: Icons.schedule_rounded,
    OrderPriority.urgent: Icons.warning_amber_rounded,
    OrderPriority.stat: Icons.bolt_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.xs.h),
          child: Text(
            AppStrings.priority.tr,
            style: AppTextStyles.titleMedium.rc(AppColors.gray900),
          ),
        ),
        Obx(
          () => Row(
            children: [
              for (final value in OrderPriority.values) ...[
                if (value != OrderPriority.values.first)
                  AppSpacing.gapH(AppSpacing.sm),
                Expanded(
                  child: PriorityCard(
                    label: controller.priorityLabel(value),
                    icon: _icons[value]!,
                    isSelected: value == controller.priority.value,
                    onTap: () => controller.selectPriority(value),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The catalogue's trailing row: a test the list does not offer.
class _FreeTextRow extends StatelessWidget {
  const _FreeTextRow({required this.hint, required this.onChanged});

  final String hint;
  final ValueChanged<String> onChanged;

  static const double _height = 56;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height.h,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.base.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rXl,
      ),
      alignment: Alignment.centerLeft,
      // No controller passed: the field owns its own.
      child: TextField(
        onChanged: onChanged,
        cursorColor: AppColors.primary800,
        style: AppTextStyles.bodyLarge.rc(AppColors.authInk),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: AppTextStyles.bodyLarge.rc(AppColors.gray900),
        ),
      ),
    );
  }
}
