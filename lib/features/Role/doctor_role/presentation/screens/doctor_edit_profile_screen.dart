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
import '../../data/static/doctor_practice_data.dart';
import '../controllers/doctor_profile_controller.dart';
import '../widgets/app_dropdown_field.dart';
import '../widgets/dashed_drop_zone.dart';

/// The practitioner's registration details.
class DoctorEditProfileScreen extends GetView<DoctorProfileController> {
  const DoctorEditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.editProfile.tr),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.gapV(AppSpacing.base),
            _Label(AppStrings.fullName.tr),
            AppTextField(
              initialText: controller.fullName.value,
              hint: AppStrings.fullName.tr,
              textInputAction: TextInputAction.next,
              onChanged: (value) => controller.fullName.value = value,
            ),
            AppSpacing.gapV(AppSpacing.sm),
            _Label(AppStrings.email.tr),
            AppTextField(
              initialText: controller.email.value,
              hint: AppStrings.emailHint.tr,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              onChanged: (value) => controller.email.value = value,
            ),
            AppSpacing.gapV(AppSpacing.sm),
            _Label(AppStrings.password.tr),
            AppTextField(
              hint: AppStrings.passwordHint.tr,
              obscureText: true,
              showPasswordToggle: true,
              textInputAction: TextInputAction.next,
              onChanged: (value) => controller.password.value = value,
            ),
            AppSpacing.gapV(AppSpacing.sm),
            _Label(AppStrings.specialty.tr),
            Obx(
              () => AppDropdownField(
                value: controller.specialty.value,
                options: DoctorPracticeData.specialties,
                onChanged: controller.selectSpecialty,
              ),
            ),
            AppSpacing.gapV(AppSpacing.sm),
            _Label(AppStrings.countryOfPractice.tr),
            Obx(
              () => AppDropdownField(
                value: controller.country.value,
                options: DoctorPracticeData.countries,
                onChanged: controller.selectCountry,
              ),
            ),
            AppSpacing.gapV(AppSpacing.sm),
            _Label(AppStrings.preferredLanguage.tr),
            Obx(
              () => AppDropdownField(
                value: controller.language.value,
                options: DoctorPracticeData.languages,
                onChanged: controller.selectLanguage,
              ),
            ),
            AppSpacing.gapV(AppSpacing.sm),
            _Label(AppStrings.experience.tr),
            AppTextField(
              initialText: controller.experience.value,
              hint: AppStrings.experience.tr,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onChanged: (value) => controller.experience.value = value,
            ),
            AppSpacing.gapV(AppSpacing.sm),
            _Label(AppStrings.biographyLabel.tr),
            _BiographyField(
              onChanged: (value) => controller.biography.value = value,
            ),
            AppSpacing.gapV(AppSpacing.sm),
            _Label(AppStrings.licenseNumber.tr),
            AppTextField(
              hint: AppStrings.licenseNumberHint.tr,
              textInputAction: TextInputAction.done,
              onChanged: (value) => controller.licenceNumber.value = value,
            ),
            AppSpacing.gapV(AppSpacing.sm),
            _Label(AppStrings.uploadLicense.tr),
            Obx(
              () => DashedDropZone(
                hasFile: controller.hasLicenceDocument.value,
                onTap: controller.attachLicence,
              ),
            ),
            AppSpacing.gapV(AppSpacing.base),
            const _ReviewNote(),
            AppSpacing.gapV(AppSpacing.base),
            AppButton(label: AppStrings.next.tr, onPressed: controller.submit),
            AppSpacing.gapV(AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: AppSpacing.xs2.h),
    child: Text(label, style: AppTextStyles.bodyMedium.rc(AppColors.gray600)),
  );
}

/// Three-line box; `AppTextField` is the app's fixed single-line control.
class _BiographyField extends StatelessWidget {
  const _BiographyField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm.w,
        vertical: AppSpacing.xs.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: AppRadius.rLg,
        border: Border.all(
          color: AppColors.fieldBorder,
          width: AppSizes.borderWidth,
        ),
      ),
      // No controller passed: the field owns its own.
      child: TextField(
        onChanged: onChanged,
        maxLines: 3,
        minLines: 3,
        cursorColor: AppColors.primary800,
        style: AppTextStyles.bodyLarge.rc(AppColors.authInk),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: AppStrings.biographyHint.tr,
          hintStyle: AppTextStyles.bodyLarge.rc(AppColors.fieldHint),
        ),
      ),
    );
  }
}

class _ReviewNote extends StatelessWidget {
  const _ReviewNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      decoration: BoxDecoration(
        color: AppColors.tagInfoSurface,
        borderRadius: AppRadius.rLg,
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${AppStrings.noteLabel.tr} ',
              style: AppTextStyles.bodyLarge.rw(
                AppColors.actionFill,
                FontWeight.w700,
              ),
            ),
            TextSpan(
              text: AppStrings.registrationReviewNote.tr,
              style: AppTextStyles.bodyLarge.rc(AppColors.link),
            ),
          ],
        ),
      ),
    );
  }
}
