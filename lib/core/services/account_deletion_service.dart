import 'package:get/get.dart';

import '../constants/app_strings.dart';
import '../exceptions/app_exceptions.dart';
import '../routes/app_routes.dart';
import '../utils/app_navigator.dart';
import '../widgets/app_snackbar.dart';
import '../../features/Role/patient/auth/domain/usecases/email_auth_usecases.dart';
import '../../features/Role/patient/profile/domain/repositories/account_repository.dart';

/// Closes the signed-in account and takes the app back to the start.
///
/// Shared because two screens offer the action — Settings and My Health
/// profile — and both used to print a snackbar and leave the account exactly
/// where it was. One implementation means they cannot drift into doing
/// different things under the same words.
///
/// The caller confirms first; both screens already show `AppConfirmDialog`.
class AccountDeletionService {
  AccountDeletionService({AccountRepository? account, Logout? logout})
    : _account = account ?? Get.find<AccountRepository>(),
      _logout = logout ?? Get.find<Logout>();

  final AccountRepository _account;
  final Logout _logout;

  bool _running = false;

  /// Returns whether the account was closed.
  Future<bool> deleteAccount() async {
    if (_running) return false;
    _running = true;
    try {
      await _account.deleteAccount();
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return false;
    } finally {
      _running = false;
    }

    // The server has already revoked the sessions; this drops the local tokens
    // so the next launch does not restore a dead one.
    try {
      await _logout();
    } on AppException {
      // The account is closed either way, and the tokens are cleared locally
      // regardless of what the sign-out call answered.
    }

    AppNavigator.resetTo(AppRoutes.onboarding);
    AppSnackbar.success(AppStrings.accountDeleted.tr);
    return true;
  }
}
