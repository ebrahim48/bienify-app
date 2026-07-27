import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/usecases/email_auth_usecases.dart';

/// Email + password sign-in.
class LoginController extends GetxController
    with SubmissionMixin, FieldErrorMixin {
  LoginController({required LoginWithEmail loginWithEmail})
    : _loginWithEmail = loginWithEmail;

  final LoginWithEmail _loginWithEmail;

  static const String emailField = 'email';
  static const String passwordField = 'password';

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> login() async {
    final isValid = validate({
      emailField: Validators.email(emailController.text),
      passwordField: Validators.password(passwordController.text),
    });
    if (!isValid) return;

    await submit(() async {
      final session = await _loginWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      Get.offAllNamed<void>(
        session.requiresProfileSetup ? AppRoutes.profileSetup : AppRoutes.home,
      );
    });
  }

  /// "Reset Now" — the recovery flow starts by confirming the phone number.
  void goToForgotPassword() => Get.toNamed<void>(AppRoutes.forgotPassword);

  /// "Sign Up Now" — back to the phone-first registration entry point.
  void goToSignUp() => Get.toNamed<void>(AppRoutes.phoneNumber);
}
