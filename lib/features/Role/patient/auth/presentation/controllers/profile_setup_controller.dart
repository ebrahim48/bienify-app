import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../../../core/base/base_controller.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/utils/validators.dart';
import '../../domain/entities/age_range.dart';
import '../../domain/entities/gender.dart';
import '../../domain/usecases/registration_usecases.dart';

/// Carries the two profile-setup steps.
///
/// One controller spans both screens so step 2 can still see (and re-submit)
/// step 1 if the user backs up, and so the whole draft is disposed once.
class ProfileSetupController extends GetxController
    with SubmissionMixin, FieldErrorMixin {
  ProfileSetupController({
    required SaveProfileDetails saveProfileDetails,
    required SaveCredentials saveCredentials,
  }) : _saveProfileDetails = saveProfileDetails,
       _saveCredentials = saveCredentials;

  final SaveProfileDetails _saveProfileDetails;
  final SaveCredentials _saveCredentials;

  static const String nameField = 'name';
  static const String genderField = 'gender';
  static const String ageField = 'age';
  static const String emailField = 'email';
  static const String passwordField = 'password';
  static const String confirmPasswordField = 'confirm_password';

  // ─── Step 1 ──────────────────────────────────────────────────────────────
  final TextEditingController nameController = TextEditingController();
  final Rxn<Gender> gender = Rxn<Gender>();
  final Rxn<AgeRange> ageRange = Rxn<AgeRange>();

  // ─── Step 2 ──────────────────────────────────────────────────────────────
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void selectGender(Gender value) {
    gender.value = value;
    clearError(genderField);
  }

  void selectAgeRange(AgeRange value) {
    ageRange.value = value;
    clearError(ageField);
  }

  /// Step 1 → step 2.
  Future<void> submitDetails() async {
    final isValid = validate({
      nameField: Validators.name(nameController.text),
      genderField: gender.value == null
          ? AppStrings.errorGenderRequired.tr
          : null,
      ageField: ageRange.value == null ? AppStrings.errorAgeRequired.tr : null,
    });
    if (!isValid) return;

    final ok = await submit(() async {
      await _saveProfileDetails(
        name: nameController.text.trim(),
        gender: gender.value!,
        ageRange: ageRange.value!,
      );
    });

    if (ok) Get.toNamed<void>(AppRoutes.profileCredentials);
  }

  /// Step 2 → the "You're all set up" screen.
  Future<void> submitCredentials() async {
    final isValid = validate({
      emailField: Validators.email(emailController.text),
      passwordField: Validators.password(passwordController.text),
      confirmPasswordField: Validators.confirmPassword(
        confirmPasswordController.text,
        passwordController.text,
      ),
    });
    if (!isValid) return;

    final ok = await submit(() async {
      await _saveCredentials(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );
    });

    if (ok) Get.offNamed<void>(AppRoutes.signupSuccess);
  }
}
