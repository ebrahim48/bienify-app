import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_field_label.dart';
import '../../../../../../core/widgets/app_inline_link.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../controllers/login_controller.dart';

/// Email + password sign-in.
class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.login.tr),
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
                  errorText: controller.errorOf(LoginController.emailField),
                  onChanged: (_) =>
                      controller.clearError(LoginController.emailField),
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
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  errorText: controller.errorOf(LoginController.passwordField),
                  onChanged: (_) =>
                      controller.clearError(LoginController.passwordField),
                  onSubmitted: (_) => controller.login(),
                ),
              ),
            ),
            AppSpacing.gapV(AppSpacing.md),
            AppInlineLink(
              prompt: AppStrings.forgotYourPassword.tr,
              action: AppStrings.resetNow.tr,
              onTap: controller.goToForgotPassword,
            ),
            AppSpacing.gapV(AppSpacing.xl2),
            Obx(
              () => AppButton(
                label: AppStrings.login.tr,
                isLoading: controller.isSubmitting.value,
                onPressed: controller.login,
              ),
            ),
            AppSpacing.gapV(AppSpacing.base),
            AppInlineLink(
              prompt: AppStrings.areYouNewMember.tr,
              action: AppStrings.signUpNow.tr,
              onTap: controller.goToSignUp,
            ),
            AppSpacing.gapV(AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
