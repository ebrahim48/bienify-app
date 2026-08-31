import 'package:flutter/widgets.dart';
import '../../../../../core/services/avatar_service.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/utils/app_navigator.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../doctor_role/domain/entities/doctor_practice.dart'
    show PayoutAccount;
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
      // Read alongside the figures rather than when the sheet opens, so the
      // Withdraw button knows whether it has anywhere to pay before it is
      // tapped.
      await loadPayoutAccounts();
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

  // ─── Payout ──────────────────────────────────────────────────────────────
  //
  // The Earnings tab drew a bar toward the platform minimum and offered
  // nothing to do about it: a courier could watch money accumulate and never
  // ask for any of it, though the endpoints have existed all along.

  /// Where the courier can be paid. Empty until the first read lands, and
  /// legitimately empty for a courier who has not added one.
  final RxList<PayoutAccount> payoutAccounts = <PayoutAccount>[].obs;

  final RxBool isRequestingPayout = false.obs;

  /// The account a payout goes to: the courier's default, or their only one.
  PayoutAccount? get defaultPayoutAccount {
    if (payoutAccounts.isEmpty) return null;
    return payoutAccounts.firstWhereOrNull((a) => a.isDefault) ??
        payoutAccounts.first;
  }

  /// Why the last read of [payoutAccounts] failed, or null if it did not.
  ///
  /// Kept because "you have no payout accounts" and "we could not find out"
  /// are different facts and the sheet must not state the first when it means
  /// the second. This read used to swallow every failure and clear the list,
  /// so a backend that was not running, an expired session and a 500 all
  /// rendered as "Add a payout account first" — a courier who had a payout
  /// account read that as the app losing it, and a courier who did not was
  /// sent to a form that could not save either. The list is left untouched on
  /// a failure for the same reason: accounts already read are still real.
  final RxnString payoutAccountsError = RxnString();

  Future<void> loadPayoutAccounts() async {
    try {
      payoutAccounts.value = await _repository.payoutAccounts();
      payoutAccountsError.value = null;
    } on AppException catch (e) {
      payoutAccountsError.value = e.message;
    }
  }

  /// Asks for a payout of [amount] into [accountId].
  ///
  /// Returns whether it was filed, so the sheet knows whether to close. The
  /// figures are re-read either way: a request that succeeded moves money into
  /// `pendingWithdrawal`, and the screen must not keep offering it twice.
  Future<bool> requestPayout(double amount, String accountId) async {
    if (isRequestingPayout.value) return false;
    isRequestingPayout.value = true;
    try {
      await _repository.requestWithdrawal(
        amount: amount,
        payoutAccountId: accountId,
      );
    } on AppException catch (e) {
      // The server owns the rules a courier can fall foul of — below the
      // minimum, more than the balance, one already in flight — so its own
      // words are shown rather than a guess at which one it was.
      AppSnackbar.error(e.message);
      return false;
    } finally {
      isRequestingPayout.value = false;
    }
    await load();
    AppSnackbar.success(AppStrings.payoutRequested.tr);
    return true;
  }

  final RxBool isSavingPayoutAccount = false.obs;

  /// Files somewhere the courier can be paid, then re-reads the list so the
  /// payout sheet can select it straight away.
  ///
  /// Returns whether it landed. It used to return nothing, which left the
  /// caller unable to tell a saved account from a refused one — and nothing
  /// called it at all: the method and its repository behind it existed, while
  /// no screen in the rider role ever opened a form. A courier was told to
  /// "add a payout account first" by a sheet that offered no way to add one.
  Future<bool> addPayoutAccount({
    required String kind,
    required String displayName,
    required String accountNumber,
    String? bankName,
  }) async {
    if (isSavingPayoutAccount.value) return false;

    final name = displayName.trim();
    final number = accountNumber.trim();
    // The server takes four digits at minimum; checking here names the field
    // rather than returning a validation error about the whole body.
    if (name.isEmpty || number.length < 4) {
      AppSnackbar.info(AppStrings.payoutAccountNeedsDetails.tr);
      return false;
    }

    isSavingPayoutAccount.value = true;
    try {
      await _repository.addPayoutAccount(
        kind: kind,
        displayName: name,
        accountNumber: number,
        bankName: bankName?.trim(),
      );
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return false;
    } finally {
      isSavingPayoutAccount.value = false;
    }

    await loadPayoutAccounts();
    AppSnackbar.success(AppStrings.payoutAccountAdded.tr);
    return true;
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
