import 'package:get/get.dart';

import '../constants/app_strings.dart';
import '../exceptions/app_exceptions.dart';
import '../widgets/app_snackbar.dart';

/// Shared behaviour for any controller that submits a form.
///
/// Gives every screen the same loading flag, the same double-tap guard and
/// the same error reporting, so a controller only ever writes the happy path:
///
/// ```dart
/// void login() => submit(() async {
///   final session = await _loginWithEmail(email: ..., password: ...);
///   Get.offAllNamed(AppRoutes.home);
/// });
/// ```
mixin SubmissionMixin on GetxController {
  /// True while an action started by [submit] is in flight; bind it to a
  /// button's `isLoading`.
  final RxBool isSubmitting = false.obs;

  /// Runs [action], reporting any `AppException` through [AppSnackbar] and
  /// ignoring re-entrant calls.
  ///
  /// Returns `true` when [action] completed without throwing, which lets a
  /// caller chain navigation only on success.
  Future<bool> submit(Future<void> Function() action) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;
    try {
      await action();
      return true;
    } on NoInternetException {
      AppSnackbar.error(AppStrings.noInternetConnection.tr);
    } on AppException catch (error) {
      AppSnackbar.error(error.message);
    } catch (_) {
      AppSnackbar.error(AppStrings.somethingWentWrong.tr);
    } finally {
      isSubmitting.value = false;
    }
    return false;
  }
}

/// Adds inline field errors that clear as soon as the user edits the field.
///
/// Errors live in an observable map keyed by field name so a screen can bind
/// `controller.errorOf('email')` straight to `AppTextField.errorText`.
mixin FieldErrorMixin on GetxController {
  final RxMap<String, String?> fieldErrors = <String, String?>{}.obs;

  String? errorOf(String field) => fieldErrors[field];

  void setError(String field, String? message) => fieldErrors[field] = message;

  void clearError(String field) {
    if (fieldErrors[field] != null) fieldErrors[field] = null;
  }

  void clearAllErrors() => fieldErrors.clear();

  /// Applies [validations] and returns true when every entry passed.
  ///
  /// ```dart
  /// final ok = validate({
  ///   'email': Validators.email(emailController.text),
  ///   'password': Validators.password(passwordController.text),
  /// });
  /// ```
  bool validate(Map<String, String?> validations) {
    validations.forEach(setError);
    return validations.values.every((message) => message == null);
  }
}
