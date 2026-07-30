import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/app_navigator.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/usecases/password_recovery_usecases.dart';
import 'auth_flow.dart';

/// Final step of password recovery: choose and confirm a new password.
class NewPasswordController extends GetxController
    with SubmissionMixin, FieldErrorMixin {
  NewPasswordController({
    required NewPasswordArguments arguments,
    required ResetPassword resetPassword,
  }) : _resetToken = arguments.resetToken,
       _resetPassword = resetPassword;

  final String _resetToken;
  final ResetPassword _resetPassword;

  static const String passwordField = 'password';
  static const String confirmPasswordField = 'confirm_password';

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void onClose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  Future<void> resetPassword() async {
    final isValid = validate({
      passwordField: Validators.password(passwordController.text),
      confirmPasswordField: Validators.confirmPassword(
        confirmPasswordController.text,
        passwordController.text,
      ),
    });
    if (!isValid) return;

    final ok = await submit(() async {
      await _resetPassword(
        resetToken: _resetToken,
        newPassword: passwordController.text,
      );
    });

    if (ok) AppNavigator.resetTo(AppRoutes.passwordUpdated);
  }
}
