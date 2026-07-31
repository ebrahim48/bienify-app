import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_field_label.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../controllers/change_password_controller.dart';

/// Change Password, reached from Settings.
///
/// Unlike the recovery form, no `TextEditingController` is passed: each
/// `AppTextField` owns its own and reports through `onChanged`, so nothing is
/// disposed out from under the widget when the route pops.
class ChangePasswordScreen extends GetView<ChangePasswordController> {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.changePassword.tr),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ScreenTopGap(),
            AppLabeledField(
              label: AppStrings.oldPasswordLabel.tr,
              child: Obx(
                () => AppTextField(
                  hint: AppStrings.oldPasswordHint.tr,
                  obscureText: true,
                  showPasswordToggle: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.password],
                  errorText: controller.errorOf(
                    ChangePasswordController.oldPasswordField,
                  ),
                  onChanged: (value) {
                    controller.oldPassword.value = value;
                    controller.clearError(
                      ChangePasswordController.oldPasswordField,
                    );
                  },
                ),
              ),
            ),
            AppSpacing.gapV(AppSpacing.fieldGap),
            AppLabeledField(
              label: AppStrings.newPasswordLabel2.tr,
              child: Obx(
                () => AppTextField(
                  hint: AppStrings.newPasswordHint2.tr,
                  obscureText: true,
                  showPasswordToggle: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  errorText: controller.errorOf(
                    ChangePasswordController.passwordField,
                  ),
                  onChanged: (value) {
                    controller.newPassword.value = value;
                    controller.clearError(
                      ChangePasswordController.passwordField,
                    );
                  },
                ),
              ),
            ),
            AppSpacing.gapV(AppSpacing.fieldGap),
            AppLabeledField(
              label: AppStrings.reEnterNewPasswordLabel.tr,
              child: Obx(
                () => AppTextField(
                  hint: AppStrings.reEnterNewPasswordHint.tr,
                  obscureText: true,
                  showPasswordToggle: true,
                  textInputAction: TextInputAction.done,
                  errorText: controller.errorOf(
                    ChangePasswordController.confirmPasswordField,
                  ),
                  onChanged: (value) {
                    controller.confirmPassword.value = value;
                    controller.clearError(
                      ChangePasswordController.confirmPasswordField,
                    );
                  },
                  onSubmitted: (_) => controller.changePassword(),
                ),
              ),
            ),
            AppSpacing.gapV(AppSpacing.lg),
            Obx(
              () => AppButton(
                label: AppStrings.changePassword.tr,
                isLoading: controller.isSubmitting.value,
                onPressed: controller.changePassword,
              ),
            ),
            AppSpacing.gapV(AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
