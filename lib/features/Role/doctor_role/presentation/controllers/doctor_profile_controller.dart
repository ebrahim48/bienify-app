import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/utils/app_navigator.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../patient/profile/data/static/profile_mock_data.dart';
import '../../../patient/profile/domain/entities/profile.dart';
import '../../data/static/doctor_practice_data.dart';

/// Backs the doctor's Profile tab and the edit form behind it.
///
/// My Wallet, Settings and Partner with Bienify are the patient app's own
/// screens — the practitioner has the same wallet and the same legal pages, so
/// they are navigated to rather than rebuilt.
class DoctorProfileController extends GetxController {
  final Rx<PatientProfile> profile = ProfileMockData.patient.obs;

  // ─── Menu ────────────────────────────────────────────────────────────────

  void openWallet() => Get.toNamed<void>(AppRoutes.wallet);

  void openSettings() => Get.toNamed<void>(AppRoutes.settings);

  void openPartner() => Get.toNamed<void>(AppRoutes.becomePartner);

  void openResultsToReview() =>
      Get.toNamed<void>(AppRoutes.doctorResultsToReview);

  void edit() => Get.toNamed<void>(AppRoutes.doctorEditProfile);

  void changePhoto() => edit();

  void logOut() {
    AppSnackbar.info(AppStrings.logOut.tr);
    AppNavigator.resetTo(AppRoutes.onboarding);
  }

  // ─── Edit form ───────────────────────────────────────────────────────────
  //
  // Held as plain strings so the inputs own their text controllers.

  final RxString fullName = 'Tamim'.obs;
  final RxString email = 'alex@gmail.com'.obs;
  final RxString password = ''.obs;
  final RxString specialty = DoctorPracticeData.specialties.first.obs;
  final RxString country = DoctorPracticeData.countries.first.obs;
  final RxString language = DoctorPracticeData.languages.first.obs;
  final RxString experience = '8'.obs;
  final RxString biography = ''.obs;
  final RxString licenceNumber = ''.obs;

  /// Whether a licence document has been attached.
  final RxBool hasLicenceDocument = false.obs;

  void selectSpecialty(String value) => specialty.value = value;

  void selectCountry(String value) => country.value = value;

  void selectLanguage(String value) => language.value = value;

  /// UI-only: file capture is a marked seam, so this records the intent.
  void attachLicence() => hasLicenceDocument.value = true;

  void submit() {
    AppSnackbar.success(AppStrings.profileSubmitted.tr);
    Get.back<void>();
  }
}
