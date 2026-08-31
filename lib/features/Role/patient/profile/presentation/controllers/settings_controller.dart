import 'package:get/get.dart';

import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/services/account_deletion_service.dart';
import '../../domain/entities/profile.dart';

/// Backs the Settings list. Four rows, three of which open the same
/// `LegalScreen` with a different document, plus the destructive action.
class SettingsController extends GetxController {
  SettingsController({AccountDeletionService? deletion})
    : _deletion = deletion ?? AccountDeletionService();

  final AccountDeletionService _deletion;

  void openChangePassword() => Get.toNamed<void>(AppRoutes.changePassword);

  /// Confirmed in the screen first, then actually closed on the server.
  Future<void> deleteAccount() => _deletion.deleteAccount();

  void openAboutUs() => _openLegal(LegalDocument.aboutUs);

  void openTerms() => _openLegal(LegalDocument.terms);

  void openPrivacy() => _openLegal(LegalDocument.privacy);

  void _openLegal(LegalDocument document) =>
      Get.toNamed<void>(AppRoutes.legal, arguments: document);
}
