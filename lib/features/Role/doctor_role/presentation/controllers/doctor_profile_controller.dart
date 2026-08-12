import 'package:get/get.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/utils/app_navigator.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../patient/auth/domain/usecases/email_auth_usecases.dart';
import '../../../patient/profile/domain/entities/profile.dart';
import '../../data/static/doctor_practice_data.dart';
import '../../domain/repositories/doctor_practice_repository.dart';

/// Backs the doctor's Profile tab and the edit form behind it.
///
/// My Wallet, Settings and Partner with Bienify are the patient app's own
/// screens — the practitioner has the same wallet and the same legal pages, so
/// they are navigated to rather than rebuilt.
class DoctorProfileController extends GetxController {
  DoctorProfileController({
    DoctorPracticeRepository? repository,
    Logout? logout,
  }) : _repository = repository ?? Get.find<DoctorPracticeRepository>(),
       _logout = logout ?? Get.find<Logout>();

  final DoctorPracticeRepository _repository;
  final Logout _logout;

  final Rx<PatientProfile> profile = const PatientProfile(
    name: '',
    maskedPhone: '',
  ).obs;

  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;
  final RxnString error = RxnString();

  /// Bumped when a load lands, so the edit form's prefilled fields are rebuilt
  /// against the values that arrived. They own their text controllers and seed
  /// them once, so a changed value only reaches them through a changed key.
  final RxInt formGeneration = 0.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final details = await _repository.profileDetails();
      profile.value = PatientProfile(
        name: details.fullName,
        // The practice profile carries an email, not a phone; the header
        // prints whichever contact it has.
        maskedPhone: details.email,
        photoUrl: details.photoUrl,
        // A practitioner without an uploaded photo still gets a portrait
        // rather than a monogram, as every other people row in the app does.
        photoAsset: AppAssets.doctorPlaceholder,
      );
      fullName.value = details.fullName;
      email.value = details.email;
      // Both pickers are decorated lists and the server stores bare codes, so
      // the code has to be resolved back to a row. A value the picker does not
      // hold is not merely wrong on screen — `DropdownButton` asserts on it.
      specialty.value = DoctorPracticeData.specialtyOptionOf(details.specialty);
      language.value =
          DoctorPracticeData.languageByCode[details.language.toLowerCase()] ??
          DoctorPracticeData.languages.first;
      experience.value = details.experience;
      biography.value = details.biography;
      licenceNumber.value = details.licenceNumber;
      hasLicenceDocument.value = details.licenceNumber.isNotEmpty;
      formGeneration.value++;
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Menu ────────────────────────────────────────────────────────────────

  void openWallet() => Get.toNamed<void>(AppRoutes.wallet);

  void openSettings() => Get.toNamed<void>(AppRoutes.settings);

  void openPartner() => Get.toNamed<void>(AppRoutes.becomePartner);

  void openResultsToReview() =>
      Get.toNamed<void>(AppRoutes.doctorResultsToReview);

  void edit() => Get.toNamed<void>(AppRoutes.doctorEditProfile);

  void changePhoto() => edit();

  /// Clears the session before leaving, so the next sign-in does not inherit
  /// this practitioner's tokens.
  Future<void> logOut() async {
    try {
      await _logout();
    } on AppException {
      // A server that refuses the sign-out still has to let the practitioner
      // leave; the local tokens are dropped either way.
    }
    AppNavigator.resetTo(AppRoutes.onboarding);
  }

  // ─── Edit form ───────────────────────────────────────────────────────────
  //
  // Held as plain strings so the inputs own their text controllers.

  final RxString fullName = ''.obs;
  final RxString email = ''.obs;
  final RxString password = ''.obs;
  final RxString specialty = DoctorPracticeData.specialties.first.obs;
  final RxString country = DoctorPracticeData.countries.first.obs;
  final RxString language = DoctorPracticeData.languages.first.obs;
  final RxString experience = ''.obs;
  final RxString biography = ''.obs;
  final RxString licenceNumber = ''.obs;

  /// Whether a licence document has been attached.
  final RxBool hasLicenceDocument = false.obs;

  void selectSpecialty(String value) => specialty.value = value;

  void selectCountry(String value) => country.value = value;

  void selectLanguage(String value) => language.value = value;

  /// Uploading the file itself is a marked seam; the licence number is what
  /// the practice profile actually stores.
  void attachLicence() => hasLicenceDocument.value = true;

  Future<void> submit() async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      // Sent as codes, not as the decorated rows — storing `🇬🇧  English` as a
      // language would make the profile unreadable to every other client.
      await _repository.saveProfileDetails(
        specialty: DoctorPracticeData.specialtyCodeOf(specialty.value),
        experience: experience.value,
        biography: biography.value,
        licenceNumber: licenceNumber.value,
        language: DoctorPracticeData.languageCodeOf(language.value),
      );
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    } finally {
      isSubmitting.value = false;
    }
    AppSnackbar.success(AppStrings.profileSubmitted.tr);
    await load();
    Get.back<void>();
  }
}
