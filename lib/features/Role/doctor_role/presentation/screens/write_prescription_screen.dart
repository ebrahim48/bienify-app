import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../../../core/widgets/app_top_bar.dart';
import '../widgets/app_dropdown_field.dart';
import '../../domain/entities/doctor_practice.dart';
import '../controllers/write_prescription_controller.dart';

/// Write Prescriptions: the lines already on the script, then the form that
/// adds another.
class WritePrescriptionScreen extends GetView<WritePrescriptionController> {
  const WritePrescriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.writePrescriptions.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          // Read here so the list repaints when a line is saved.
          Obx(() {
            final medicines = controller.medicines.toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final medicine in medicines) ...[
                  _MedicineCard(
                    medicine: medicine,
                    dosage: controller.dosageFor(medicine),
                  ),
                  AppSpacing.gapV(AppSpacing.sm),
                ],
              ],
            );
          }),
          AppSpacing.gapV(AppSpacing.xs),
          _AddButton(onTap: controller.openForm),
          AppSpacing.gapV(AppSpacing.base),
          Obx(
            () => controller.isFormOpen.value
                ? _MedicineForm(
                    // A new key on every save rebuilds the fields empty: they
                    // own their text controllers, so clearing them means
                    // giving them fresh ones.
                    key: ValueKey(controller.formGeneration.value),
                    controller: controller,
                  )
                : const SizedBox.shrink(),
          ),
          AppSpacing.gapV(AppSpacing.md),
          // "Send to Patient" appears once a line has been written, as
          // the design shows it only on the second screen.
          Obx(
            () => controller.hasSaved.value
                ? AppButton(
                    label: AppStrings.submitYourPatients.tr,
                    onPressed: controller.submit,
                  )
                : const SizedBox.shrink(),
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

/// One written line: name, a duration pill, then the three detail rows.
class _MedicineCard extends StatelessWidget {
  const _MedicineCard({required this.medicine, required this.dosage});

  final PrescribedMedicine medicine;

  /// `(dose, frequency)`.
  final (String, String) dosage;

  @override
  Widget build(BuildContext context) {
    final (dose, frequency) = dosage;

    return Container(
      padding: EdgeInsets.all(AppSpacing.sm.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rLg,
        border: Border.all(
          color: AppColors.surfaceBorder,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  medicine.name,
                  style: AppTextStyles.titleMedium.rw(
                    AppColors.gray900,
                    FontWeight.w400,
                  ),
                ),
              ),
              AppSpacing.gapH(AppSpacing.xs),
              _DurationPill(label: medicine.durationLabel),
            ],
          ),
          AppSpacing.gapV(AppSpacing.xs),
          _Detail(label: AppStrings.dosageLabel.tr, value: dose),
          _Detail(label: AppStrings.frequencyLabel.tr, value: frequency),
          if (medicine.notes.isNotEmpty)
            _Detail(
              label: AppStrings.instructionsLabel.tr,
              value: medicine.notes,
            ),
        ],
      ),
    );
  }
}

class _DurationPill extends StatelessWidget {
  const _DurationPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs.w,
        vertical: AppSpacing.xxs.h,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.rFull,
        border: Border.all(
          color: AppColors.surfaceBorder,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Text(label, style: AppTextStyles.bodyMedium.rc(AppColors.gray900)),
    );
  }
}

/// `Dosage: 1 capsule` — bold label, plain value, wrapping under it.
class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xxs.h),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: AppTextStyles.bodyLarge.rw(
                AppColors.gray900,
                FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: AppColors.actionFill,
        borderRadius: AppRadius.rLg,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm.w,
              vertical: AppSpacing.xs.h,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: AppSizes.xl.w,
                  color: AppColors.actionLabel,
                ),
                AppSpacing.gapH(AppSpacing.xs2),
                Text(
                  AppStrings.addNewMedicine.tr,
                  style: AppTextStyles.bodyLarge.rc(AppColors.actionLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The four labelled inputs and Save. No `TextEditingController` is passed:
/// each field owns its own, so nothing is disposed out from under it.
class _MedicineForm extends StatelessWidget {
  const _MedicineForm({super.key, required this.controller});

  final WritePrescriptionController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(AppStrings.medicineName.tr),
        AppTextField(
          hint: AppStrings.prescriptionMedicineNameHint.tr,
          textInputAction: TextInputAction.next,
          onChanged: controller.setName,
        ),
        AppSpacing.gapV(AppSpacing.sm),

        // Strength and its unit sit on one line: they are one fact, and the
        // number means nothing without the unit beside it.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FieldLabel(AppStrings.strengthLabel.tr),
                  AppTextField(
                    hint: AppStrings.strengthHint.tr,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    onChanged: controller.setStrength,
                  ),
                ],
              ),
            ),
            AppSpacing.gapH(AppSpacing.sm),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FieldLabel(AppStrings.unitLabel.tr),
                  Obx(
                    () => AppDropdownField(
                      value: controller.unit.value.label,
                      options: [
                        for (final unit in DoseUnit.values) unit.label,
                      ],
                      onChanged: (label) => controller.setUnit(
                        DoseUnit.values.firstWhere((u) => u.label == label),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        AppSpacing.gapV(AppSpacing.sm),

        _FieldLabel(AppStrings.timesPerDayLabel.tr),
        Obx(
          () => _ChoiceChips(
            labels: [
              for (final n in WritePrescriptionController.dailyFrequencies)
                '$n',
            ],
            selectedIndex: WritePrescriptionController.dailyFrequencies.indexOf(
              controller.timesPerDay.value,
            ),
            onSelected: (index) => controller.setTimesPerDay(
              WritePrescriptionController.dailyFrequencies[index],
            ),
          ),
        ),
        AppSpacing.gapV(AppSpacing.sm),

        _FieldLabel(AppStrings.whenToTakeLabel.tr),
        Obx(
          () => _ChoiceChips(
            labels: [
              for (final timing in MealTiming.values)
                controller.timingLabel(timing),
            ],
            selectedIndex: MealTiming.values.indexOf(controller.timing.value),
            onSelected: (index) =>
                controller.setTiming(MealTiming.values[index]),
          ),
        ),
        AppSpacing.gapV(AppSpacing.sm),

        _FieldLabel(AppStrings.enterDurationInDays.tr),
        AppTextField(
          hint: AppStrings.enterDurationInDays.tr,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          onChanged: controller.setDuration,
        ),
        AppSpacing.gapV(AppSpacing.sm),
        _FieldLabel(AppStrings.notesLabel.tr),
        AppTextField(
          hint: AppStrings.notesHint.tr,
          textInputAction: TextInputAction.done,
          onChanged: controller.setNotes,
          onSubmitted: (_) => controller.save(),
        ),
        AppSpacing.gapV(AppSpacing.base),
        // Sized to its label and left-aligned, as the design places it.
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            label: AppStrings.save.tr,
            expanded: false,
            radius: AppRadius.xl3,
            onPressed: controller.save,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: AppSpacing.xs2.h),
    child: Text(label, style: AppTextStyles.bodyMedium.rc(AppColors.gray600)),
  );
}

/// A row of single-choice chips.
///
/// Used where the answer is one of a short, known set — how many doses a day,
/// and when they are taken. Typing those as free text is how one script says
/// "after meals" and the next says "p.c.".
class _ChoiceChips extends StatelessWidget {
  const _ChoiceChips({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs.w,
      runSpacing: AppSpacing.xs.h,
      children: [
        for (final (index, label) in labels.indexed)
          _Chip(
            label: label,
            isSelected: index == selectedIndex,
            onTap: () => onSelected(index),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.actionFill : AppColors.surface,
      borderRadius: AppRadius.rXl3,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.rXl3,
            border: Border.all(
              color: isSelected ? AppColors.actionFill : AppColors.fieldBorder,
              width: AppSizes.borderWidth,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm.w,
            vertical: AppSpacing.xs.h,
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.rc(
              isSelected ? AppColors.actionLabel : AppColors.gray700,
            ),
          ),
        ),
      ),
    );
  }
}
