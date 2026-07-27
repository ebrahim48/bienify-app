import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../controllers/new_password_controller.dart';

/// "Enter New Password" — the last step of password recovery.
class NewPasswordScreen extends GetView<NewPasswordController> {
  const NewPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.enterNewPassword.tr),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ScreenTopGap(),
            AppLabeledField(
              label: AppStrings.password.tr,
              child: Obx(
                () => AppTextField(
                  controller: controller.passwordController,
                  hint: AppStrings.newPasswordHint.tr,
                  obscureText: true,
                  showPasswordToggle: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  errorText: controller.errorOf(
                    NewPasswordController.passwordField,
                  ),
                  onChanged: (_) => controller.clearError(
                    NewPasswordController.passwordField,
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
                  hint: AppStrings.retypeNewPasswordHint.tr,
                  obscureText: true,
                  showPasswordToggle: true,
                  textInputAction: TextInputAction.done,
                  errorText: controller.errorOf(
                    NewPasswordController.confirmPasswordField,
                  ),
                  onChanged: (_) => controller.clearError(
                    NewPasswordController.confirmPasswordField,
                  ),
                  onSubmitted: (_) => controller.resetPassword(),
                ),
              ),
            ),
            AppSpacing.gapV(AppSpacing.lg),
            Obx(
              () => AppButton(
                label: AppStrings.resetPassword.tr,
                isLoading: controller.isSubmitting.value,
                onPressed: controller.resetPassword,
              ),
            ),
            AppSpacing.gapV(AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
