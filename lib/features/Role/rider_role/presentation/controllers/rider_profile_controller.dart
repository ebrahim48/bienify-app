import 'package:flutter/widgets.dart';
import '../../../../../core/services/avatar_service.dart';
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
class RiderProfileController extends GetxController with AvatarChanging {
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
      // The server stores a free-text city and the pickers hold fixed lists,
      // so the stored value is added to its list rather than swapped for the
      // first entry: falling back would show a courier in Springfield as being
      // in Cameron, and saving the form would then write that back over the
      // city they actually work in.
      countryOptions.value = _withStored(RiderData.countries, loaded.country);
      cityOptions.value = _withStored(RiderData.cities, loaded.city);
      country.value = loaded.country.isEmpty
          ? RiderData.countries.first
          : loaded.country;
      city.value = loaded.city.isEmpty ? RiderData.cities.first : loaded.city;
      address.value = loaded.address;
      // The courier's own saved answers, not a fixture's. Both were reset to
      // defaults on every load because the profile carried neither.
      zones.value = List.of(loaded.zones);
      gpsEnabled.value = loaded.shareLiveLocation;
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

  /// Changes the account photo.
  ///
  /// This opened the edit form, which has no photo field — so the control did
  /// nothing at all, in all four roles.
  Future<void> changePhoto(BuildContext context) => changePhotoWith(context);

  @override
  Future<void> reloadProfile() => load();

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

  /// The picker lists, widened to hold whatever the server already stores.
  final RxList<String> countryOptions = <String>[...RiderData.countries].obs;
  final RxList<String> cityOptions = <String>[...RiderData.cities].obs;

  /// [options] with [stored] at the front when the list does not already
  /// offer it, so a dropdown can show the value it was given.
  static List<String> _withStored(List<String> options, String stored) =>
      stored.isEmpty || options.contains(stored)
      ? List.of(options)
      : [stored, ...options];
  final RxString address = ''.obs;
  final RxString zone = RiderData.zones.first.obs;
  final RxList<String> zones = <String>[].obs;
  final RxBool gpsEnabled = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Replaced by the courier's saved zones as soon as [load] returns; empty
    // rather than three the fixture picked on their behalf.
    zones.value = <String>[];
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
      // Everything the form collects. It sent three of seven fields and
      // reported success for all of them.
      await _repository.saveProfile(
        vehicleType: rider.value.vehicleType,
        licenceNumber: rider.value.licenceNumber,
        city: city.value,
        name: fullName.value,
        country: country.value,
        addressLine: address.value,
        zones: List.of(zones),
        shareLiveLocation: gpsEnabled.value,
      );
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    } finally {
      isSubmitting.value = false;
    }
    await load();
    Get.back<void>();
    AppSnackbar.success(AppStrings.riderUpdated.tr);
  }
}
