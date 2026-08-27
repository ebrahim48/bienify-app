import 'package:flutter/widgets.dart';
import '../../../../../core/services/avatar_service.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/utils/app_navigator.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../patient/auth/domain/usecases/email_auth_usecases.dart';
import '../../data/static/pharmacy_shop_data.dart';
import '../../domain/entities/pharmacy_shop.dart';
import '../../domain/repositories/pharmacy_shop_repository.dart';

/// Backs the shop's Profile tab and the edit form behind it.
///
/// Payments and Credit and Settings are the patient app's own screens — a
/// shop keeps its money in the same wallet and reads the same legal pages, so
/// they are navigated to rather than rebuilt.
class ShopProfileController extends GetxController with AvatarChanging {
  ShopProfileController({PharmacyShopRepository? repository, Logout? logout})
    : _repository = repository ?? Get.find<PharmacyShopRepository>(),
      _logout = logout ?? Get.find<Logout>();

  final PharmacyShopRepository _repository;
  final Logout _logout;

  final Rx<Shop> shop = const Shop(
    name: '',
    ownerName: '',
    phone: '',
    location: '',
    availableBalance: 0,
    email: '',
    country: '',
    address: '',
  ).obs;

  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;
  final RxnString error = RxnString();

  /// Bumped when a load lands, so the edit form's prefilled fields are rebuilt
  /// against the values that arrived.
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
      final loaded = await _repository.shop();
      shop.value = loaded;
      fullName.value = loaded.name;
      email.value = loaded.email;
      address.value = loaded.address;
      licenceNumber.value = loaded.licenceNumber;
      hasLicence.value = loaded.licenceNumber.isNotEmpty;
      // The picker holds a fixed list of countries and the server stores a
      // free-text city, so a value it does not hold would break the dropdown.
      country.value = PharmacyShopData.countries.contains(loaded.country)
          ? loaded.country
          : PharmacyShopData.countries.first;
      formGeneration.value++;
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  void openPayments() => Get.toNamed<void>(AppRoutes.wallet);

  void openSettings() => Get.toNamed<void>(AppRoutes.settings);

  void edit() => Get.toNamed<void>(AppRoutes.shopEditProfile);

  /// Changes the account photo.
  ///
  /// This opened the edit form, which has no photo field — so the control did
  /// nothing at all, in all four roles.
  Future<void> changePhoto(BuildContext context) => changePhotoWith(context);

  @override
  Future<void> reloadProfile() => load();

  /// Clears the session before leaving, so the next sign-in does not inherit
  /// this owner's tokens.
  Future<void> logOut() async {
    try {
      await _logout();
    } on AppException {
      // A server that refuses the sign-out still has to let the owner leave;
      // the local tokens are dropped either way.
    }
    AppNavigator.resetTo(AppRoutes.onboarding);
  }

  // ─── Edit form ───────────────────────────────────────────────────────────

  final RxString fullName = ''.obs;
  final RxString email = ''.obs;
  final RxString password = ''.obs;
  final RxString country = PharmacyShopData.countries.first.obs;
  final RxString address = ''.obs;
  final RxString licenceNumber = ''.obs;

  final RxBool hasLicence = false.obs;
  final RxBool hasLogo = false.obs;
  final RxBool hasBanner = false.obs;

  void selectCountry(String value) => country.value = value;

  /// Image capture is a marked seam, so these record the intent.
  void attachLicence() => hasLicence.value = true;

  void attachLogo() => hasLogo.value = true;

  void attachBanner() => hasBanner.value = true;

  Future<void> submit() async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      await _repository.saveShopDetails(
        name: fullName.value.trim(),
        address: address.value.trim(),
        city: country.value,
        licenceNumber: licenceNumber.value.trim(),
      );
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    } finally {
      isSubmitting.value = false;
    }
    await load();
    Get.back<void>();
    AppSnackbar.success(AppStrings.shopUpdated.tr);
  }
}
