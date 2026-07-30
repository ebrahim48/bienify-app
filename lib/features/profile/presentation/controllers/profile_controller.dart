import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/app_navigator.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/static/profile_mock_data.dart';
import '../../domain/entities/profile.dart';

/// Backs the Profile screen: the patient card and the menu below it.
///
/// UI-only — the patient comes from [ProfileMockData] and nothing calls an
/// API. Logging out clears the stack; everything else pushes a route.
class ProfileController extends GetxController {
  final Rx<PatientProfile> patient = ProfileMockData.patient.obs;

  // ─── Navigation ──────────────────────────────────────────────────────────

  void openHealthProfile() => Get.toNamed<void>(AppRoutes.healthProfile);

  /// Promoted to the top level by the design, so it is reachable both here
  /// and from inside the health profile.
  void openTestsAndResults() => Get.toNamed<void>(AppRoutes.testResults);

  void openOrderHistory() => Get.toNamed<void>(AppRoutes.orderHistory);

  void openWallet() => Get.toNamed<void>(AppRoutes.wallet);

  void openSettings() => Get.toNamed<void>(AppRoutes.settings);

  void openPartner() => Get.toNamed<void>(AppRoutes.becomePartner);

  // ─── Actions ─────────────────────────────────────────────────────────────

  /// Editing the profile and replacing the photo both land on the existing
  /// sign-up profile form, which is the screen that already collects them.
  void edit() => Get.toNamed<void>(AppRoutes.profileSetup);

  void changePhoto() => edit();

  /// Called once the confirm dialog resolves.
  void logOut() {
    AppSnackbar.info(AppStrings.logOut.tr);
    AppNavigator.resetTo(AppRoutes.onboarding);
  }
}
