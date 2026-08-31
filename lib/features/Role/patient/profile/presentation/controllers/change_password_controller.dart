import 'package:get/get.dart';

import '../../../../../../core/base/base_controller.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/utils/app_navigator.dart';
import '../../../../../../core/utils/validators.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../auth/domain/usecases/email_auth_usecases.dart';
import '../../../auth/domain/usecases/password_recovery_usecases.dart';

/// Backs Change Password: old password, new password, confirmation.
///
/// The three values are held as plain strings rather than
/// `TextEditingController`s so that `AppTextField` owns the text controllers
/// and disposes them with the widget; see `docs/ARCHITECTURE.md` on why a
/// GetX controller must not own one.
class ChangePasswordController extends GetxController
    with SubmissionMixin, FieldErrorMixin {
  ChangePasswordController({ChangePassword? changePassword, Logout? logout})
    : _changePassword = changePassword ?? Get.find<ChangePassword>(),
      _logout = logout ?? Get.find<Logout>();

  final ChangePassword _changePassword;
  final Logout _logout;

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

    // A wrong current password is the one failure that belongs to a field
    // rather than to the whole form, so it is caught here and reported under
    // the input that caused it instead of in a snackbar the user has to
    // connect back to a box themselves.
    var wrongCurrent = false;

    final ok = await submit(() async {
      try {
        await _changePassword(
          currentPassword: oldPassword.value,
          newPassword: newPassword.value,
        );
      } on UnauthorizedException {
        wrongCurrent = true;
        rethrow;
      }
    });

    if (!ok) {
      if (wrongCurrent) {
        setError(oldPasswordField, AppStrings.errorCurrentPassword.tr);
      }
      return;
    }

    // The server revokes every refresh session when a password changes
    // (`auth.service.ts:530`), this device's included. Staying on the profile
    // would leave the patient signed in on a dead session until some later
    // request happened to refresh and failed — so the sign-out is made
    // deliberate and explained, rather than arriving as a mystery logout.
    try {
      await _logout();
    } on AppException {
      // The local tokens are cleared regardless; there is nothing left here
      // for a failed server-side sign-out to protect.
    }

    AppNavigator.resetTo(AppRoutes.login);
    AppSnackbar.success(AppStrings.passwordChangedSignInAgain.tr);
  }
}
