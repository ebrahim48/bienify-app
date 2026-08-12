import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/utils/app_navigator.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../patient/auth/domain/usecases/email_auth_usecases.dart';
import '../../data/static/rider_data.dart';
import '../../domain/entities/rider.dart';
import '../../domain/repositories/rider_repository.dart';

/// Backs the courier's Profile tab, its edit form and the Earnings tab.
///
/// My Wallet and Settings are the patient app's own screens — a courier keeps
/// their money in the same wallet and reads the same legal pages, so they are
/// navigated to rather than rebuilt.
class RiderProfileController extends GetxController {
  RiderProfileController({RiderRepository? repository, Logout? logout})
    : _repository = repository ?? Get.find<RiderRepository>(),
      _logout = logout ?? Get.find<Logout>();

  final RiderRepository _repository;
  final Logout _logout;

  final Rx<Rider> rider = const Rider(
    name: '',
    location: '',
    todaysEarnings: 0,
    deliveriesToday: 0,
    rating: 0,
    isOnline: false,
    email: '',
    country: '',
    city: '',
    address: '',
  ).obs;

  /// Empty until the first load lands, so the Earnings tab does not print a
  /// week the courier has not worked.
  final Rx<RiderEarnings> earnings = const RiderEarnings(
    today: 0,
    todayCount: 0,
    thisWeek: 0,
    weekCount: 0,
    payoutDay: 'Friday',
    payoutMinimum: 0,
    history: [],
  ).obs;

  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;
  final RxnString error = RxnString();

  /// Bumped when a load lands, so the edit form's prefilled fields are rebuilt.
  final RxInt formGeneration = 0.obs;

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final loaded = await _repository.rider();
      rider.value = loaded;
      earnings.value = await _repository.earnings();
      fullName.value = loaded.name;
      email.value = loaded.email;
      // The pickers hold fixed lists and the server stores a free-text city,
      // so a value they do not hold would break the dropdown.
      country.value = RiderData.countries.contains(loaded.country)
          ? loaded.country
          : RiderData.countries.first;
      city.value = RiderData.cities.contains(loaded.city)
          ? loaded.city
          : RiderData.cities.first;
      address.value = loaded.address;
      formGeneration.value++;
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  void openWallet() => Get.toNamed<void>(AppRoutes.wallet);

  void openSettings() => Get.toNamed<void>(AppRoutes.settings);

  void edit() => Get.toNamed<void>(AppRoutes.riderEditProfile);

  void changePhoto() => edit();

  /// Clears the session before leaving, so the next sign-in does not inherit
  /// this courier's tokens.
  Future<void> logOut() async {
    try {
      await _logout();
    } on AppException {
      // A server that refuses the sign-out still has to let the courier leave;
      // the local tokens are dropped either way.
    }
    AppNavigator.resetTo(AppRoutes.onboarding);
  }

  // ─── Edit form ───────────────────────────────────────────────────────────
  //
  // Held as plain strings so the inputs own their text controllers.

  final RxString fullName = ''.obs;
  final RxString email = ''.obs;
  final RxString country = RiderData.countries.first.obs;
  final RxString city = RiderData.cities.first.obs;
  final RxString address = ''.obs;
  final RxString zone = RiderData.zones.first.obs;
  final RxList<String> zones = <String>[].obs;
  final RxBool gpsEnabled = true.obs;

  @override
  void onInit() {
    super.onInit();
    zones.value = List.of(RiderData.pickedZones);
    load();
  }

  void selectCountry(String value) => country.value = value;

  void selectCity(String value) => city.value = value;

  void selectZone(String value) {
    zone.value = value;
    if (!zones.contains(value)) zones.add(value);
  }

  void removeZone(String value) => zones.remove(value);

  void toggleGps(bool value) => gpsEnabled.value = value;

  Future<void> submit() async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      await _repository.saveProfile(
        vehicleType: rider.value.vehicleType,
        licenceNumber: rider.value.licenceNumber,
        city: city.value,
      );
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    } finally {
      isSubmitting.value = false;
    }
    AppSnackbar.success(AppStrings.shopUpdated.tr);
    await load();
    Get.back<void>();
  }
}
