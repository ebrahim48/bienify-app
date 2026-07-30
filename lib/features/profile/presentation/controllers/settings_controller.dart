import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../domain/entities/profile.dart';

/// Backs the Settings list. Four rows, three of which open the same
/// `LegalScreen` with a different document.
class SettingsController extends GetxController {
  void openChangePassword() => Get.toNamed<void>(AppRoutes.changePassword);

  void openAboutUs() => _openLegal(LegalDocument.aboutUs);

  void openTerms() => _openLegal(LegalDocument.terms);

  void openPrivacy() => _openLegal(LegalDocument.privacy);

  void _openLegal(LegalDocument document) =>
      Get.toNamed<void>(AppRoutes.legal, arguments: document);
}
