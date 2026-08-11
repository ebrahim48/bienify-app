import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_choice_chip.dart';
import '../../../../../../core/widgets/app_field_label.dart';
import '../../../../../../core/widgets/app_option_card.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/age_range.dart';
import '../../domain/entities/gender.dart';
import '../controllers/profile_setup_controller.dart';

/// Profile setup, step 1 — name, gender and age bracket.
class ProfileSetupScreen extends GetView<ProfileSetupController> {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.setUpYourProfile.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenTopGap(),
          _NameField(controller: controller),
          AppSpacing.gapV(AppSpacing.fieldGap),
          _GenderPicker(controller: controller),
          AppSpacing.gapV(AppSpacing.fieldGap),
          _AgePicker(controller: controller),
          AppSpacing.gapV(AppSpacing.xl2),
          Obx(
            () => AppButton(
              label: AppStrings.next.tr,
              isLoading: controller.isSubmitting.value,
              onPressed: controller.submitDetails,
            ),
          ),
          AppSpacing.gapV(AppSpacing.lg),
        ],
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller});

  final ProfileSetupController controller;

  @override
  Widget build(BuildContext context) {
    return AppLabeledField(
      label: AppStrings.name.tr,
      child: Obx(
        () => AppTextField(
          controller: controller.nameController,
          hint: AppStrings.nameHint.tr,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          errorText: controller.errorOf(ProfileSetupController.nameField),
          onChanged: (_) =>
              controller.clearError(ProfileSetupController.nameField),
          prefixIcon: Icon(
            Icons.person_outline_rounded,
            size: AppSizes.xl2.w,
            color: AppColors.fieldHint,
          ),
        ),
      ),
    );
  }
}

class _GenderPicker extends StatelessWidget {
  const _GenderPicker({required this.controller});

  final ProfileSetupController controller;

  static const Map<Gender, IconData> _icons = {
    Gender.male: Icons.person,
    Gender.female: Icons.person_2,
  };

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppFieldLabel(AppStrings.gender.tr),
          AppSpacing.gapV(AppSpacing.labelGap),
          Row(
            children: [
              for (final gender in Gender.values) ...[
                if (gender != Gender.values.first)
                  AppSpacing.gapH(AppSpacing.xs),
                Expanded(
                  child: AppOptionCard(
                    label: gender.labelKey.tr,
                    icon: _icons[gender],
                    isSelected: controller.gender.value == gender,
                    onTap: () => controller.selectGender(gender),
                  ),
                ),
              ],
            ],
          ),
          _ErrorLine(
            message: controller.errorOf(ProfileSetupController.genderField),
          ),
        ],
      ),
    );
  }
}

class _AgePicker extends StatelessWidget {
  const _AgePicker({required this.controller});

  final ProfileSetupController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppFieldLabel(AppStrings.age.tr),
          AppSpacing.gapV(AppSpacing.labelGap),
          AppChoiceChipGrid(
            children: [
              for (final range in AgeRange.values)
                AppChoiceChip(
                  label: range.label,
                  isSelected: controller.ageRange.value == range,
                  onTap: () => controller.selectAgeRange(range),
                ),
            ],
          ),
          _ErrorLine(
            message: controller.errorOf(ProfileSetupController.ageField),
          ),
        ],
      ),
    );
  }
}

/// Validation message for the pickers, which have no field of their own to
/// render one inside.
class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.xs2.h + 2,
        left: AppSpacing.xs2.w,
      ),
      child: Text(message!, style: AppTextStyles.bodySmall.rc(AppColors.error)),
    );
  }
}
