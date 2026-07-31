import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/utils/app_navigator.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../data/static/pharmacy_shop_data.dart';
import '../../domain/entities/pharmacy_shop.dart';

/// Backs the shop's Profile tab and the edit form behind it.
///
/// Payments and Credit and Settings are the patient app's own screens — a
/// shop keeps its money in the same wallet and reads the same legal pages, so
/// they are navigated to rather than rebuilt.
class ShopProfileController extends GetxController {
  final Rx<Shop> shop = PharmacyShopData.shop.obs;

  void openPayments() => Get.toNamed<void>(AppRoutes.wallet);

  void openSettings() => Get.toNamed<void>(AppRoutes.settings);

  void edit() => Get.toNamed<void>(AppRoutes.shopEditProfile);

  void changePhoto() => edit();

  void logOut() {
    AppSnackbar.info(AppStrings.logOut.tr);
    AppNavigator.resetTo(AppRoutes.onboarding);
  }

  // ─── Edit form ───────────────────────────────────────────────────────────

  final RxString fullName = PharmacyShopData.shop.name.obs;
  final RxString email = PharmacyShopData.shop.email.obs;
  final RxString password = ''.obs;
  final RxString country = PharmacyShopData.shop.country.obs;
  final RxString address = PharmacyShopData.shop.address.obs;
  final RxString licenceNumber = ''.obs;

  final RxBool hasLicence = false.obs;
  final RxBool hasLogo = false.obs;
  final RxBool hasBanner = false.obs;

  void selectCountry(String value) => country.value = value;

  /// UI-only: file capture is a marked seam, so these record the intent.
  void attachLicence() => hasLicence.value = true;

  void attachLogo() => hasLogo.value = true;

  void attachBanner() => hasBanner.value = true;

  void submit() {
    AppSnackbar.success(AppStrings.shopUpdated.tr);
    Get.back<void>();
  }
}
