import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_field_label.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../controllers/profile_setup_controller.dart';

/// Profile setup, step 2 — email and password.
class ProfileCredentialsScreen extends GetView<ProfileSetupController> {
  const ProfileCredentialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.setUpYourProfile.tr),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ScreenTopGap(),
            AppLabeledField(
              label: AppStrings.email.tr,
              child: Obx(
                () => AppTextField(
                  controller: controller.emailController,
                  hint: AppStrings.emailHint.tr,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  errorText: controller.errorOf(
                    ProfileSetupController.emailField,
                  ),
                  onChanged: (_) =>
                      controller.clearError(ProfileSetupController.emailField),
                ),
              ),
            ),
            AppSpacing.gapV(AppSpacing.fieldGap),
            AppLabeledField(
              label: AppStrings.password.tr,
              child: Obx(
                () => AppTextField(
                  controller: controller.passwordController,
                  hint: AppStrings.passwordHint.tr,
                  obscureText: true,
                  showPasswordToggle: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  errorText: controller.errorOf(
                    ProfileSetupController.passwordField,
                  ),
                  onChanged: (_) => controller.clearError(
                    ProfileSetupController.passwordField,
                  ),
                ),
              ),
            ),
            AppSpacing.gapV(AppSpacing.fieldGap),
            AppLabeledField(
              label: AppStrings.password.tr,
              child: Obx(
                () => AppTextField(
                  controller: controller.confirmPasswordController,
                  hint: AppStrings.retypePasswordHint.tr,
                  obscureText: true,
                  showPasswordToggle: true,
                  textInputAction: TextInputAction.done,
                  errorText: controller.errorOf(
                    ProfileSetupController.confirmPasswordField,
                  ),
                  onChanged: (_) => controller.clearError(
                    ProfileSetupController.confirmPasswordField,
                  ),
                  onSubmitted: (_) => controller.submitCredentials(),
                ),
              ),
            ),
            AppSpacing.gapV(AppSpacing.lg),
            Obx(
              () => AppButton(
                label: AppStrings.saveAndContinue.tr,
                isLoading: controller.isSubmitting.value,
                onPressed: controller.submitCredentials,
              ),
            ),
            AppSpacing.gapV(AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
