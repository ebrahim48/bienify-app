import 'package:get/get.dart';

import '../../../../../../core/base/base_controller.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/utils/validators.dart';
import '../../../../../../core/widgets/app_snackbar.dart';

/// Backs Change Password: old password, new password, confirmation.
///
/// UI-only — nothing is sent anywhere. The three values are held as plain
/// strings rather than `TextEditingController`s so that `AppTextField` owns
/// the text controllers and disposes them with the widget; see
/// `docs/ARCHITECTURE.md` on why a GetX controller must not own one.
class ChangePasswordController extends GetxController
    with SubmissionMixin, FieldErrorMixin {
  static const String oldPasswordField = 'old_password';
  static const String passwordField = 'password';
  static const String confirmPasswordField = 'confirm_password';

  final RxString oldPassword = ''.obs;
  final RxString newPassword = ''.obs;
  final RxString confirmPassword = ''.obs;

  Future<void> changePassword() async {
    final isValid = validate({
      // The current password only has to be present — length rules belong to
      // whatever it was set to, not to this form.
      oldPasswordField: oldPassword.value.isEmpty
          ? AppStrings.errorPasswordRequired.tr
          : null,
      passwordField: Validators.password(newPassword.value),
      confirmPasswordField: Validators.confirmPassword(
        confirmPassword.value,
        newPassword.value,
      ),
    });
    if (!isValid) return;

    final ok = await submit(() async {
      // The gateway call replaces this delay; see "Known seams".
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });

    if (!ok) return;
    Get.back<void>();
    AppSnackbar.success(AppStrings.passwordChanged.tr);
  }
}
