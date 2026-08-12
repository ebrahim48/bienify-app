import 'package:get/get.dart';

import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/utils/app_navigator.dart';
import '../../../auth/domain/usecases/email_auth_usecases.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/account_repository.dart';

/// Backs the Profile screen: the patient card and the menu below it.
///
/// Logging out clears the session and the stack; everything else pushes a
/// route.
class ProfileController extends GetxController {
  ProfileController({AccountRepository? repository, Logout? logout})
    : _repository = repository ?? Get.find<AccountRepository>(),
      _logout = logout ?? Get.find<Logout>();

  final AccountRepository _repository;
  final Logout _logout;

  /// Empty until the first load lands, so the card does not flash a name and
  /// a number belonging to nobody.
  final Rx<PatientProfile> patient = const PatientProfile(
    name: '',
    maskedPhone: '',
  ).obs;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      patient.value = await _repository.me();
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

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
  ///
  /// The session is cleared before leaving, so the next sign-in does not
  /// inherit this patient's tokens.
  Future<void> logOut() async {
    try {
      await _logout();
    } on AppException {
      // A server that refuses the sign-out still has to let the patient
      // leave; the local tokens are dropped either way.
    }
    AppNavigator.resetTo(AppRoutes.onboarding);
  }
}
