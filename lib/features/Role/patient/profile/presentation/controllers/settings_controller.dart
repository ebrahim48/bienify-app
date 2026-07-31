import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/profile.dart';

/// Backs the Settings list. Four rows, three of which open the same
/// `LegalScreen` with a different document, plus the destructive action.
class SettingsController extends GetxController {
  void openChangePassword() => Get.toNamed<void>(AppRoutes.changePassword);

  /// Confirmed in the screen first. Closing the account is a backend
  /// operation, so this records the intent the way My Health profile does.
  void deleteAccount() => AppSnackbar.info(AppStrings.deleteAccount.tr);

  void openAboutUs() => _openLegal(LegalDocument.aboutUs);

  void openTerms() => _openLegal(LegalDocument.terms);

  void openPrivacy() => _openLegal(LegalDocument.privacy);

  void _openLegal(LegalDocument document) =>
      Get.toNamed<void>(AppRoutes.legal, arguments: document);
}
