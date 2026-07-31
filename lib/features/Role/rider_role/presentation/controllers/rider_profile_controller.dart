import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/utils/app_navigator.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../data/static/rider_data.dart';
import '../../domain/entities/rider.dart';

/// Backs the courier's Profile tab, its edit form and the Earnings tab.
///
/// My Wallet and Settings are the patient app's own screens — a courier keeps
/// their money in the same wallet and reads the same legal pages, so they are
/// navigated to rather than rebuilt.
class RiderProfileController extends GetxController {
  final Rx<Rider> rider = RiderData.rider.obs;

  RiderEarnings get earnings => RiderData.earnings;

  void openWallet() => Get.toNamed<void>(AppRoutes.wallet);

  void openSettings() => Get.toNamed<void>(AppRoutes.settings);

  void edit() => Get.toNamed<void>(AppRoutes.riderEditProfile);

  void changePhoto() => edit();

  void logOut() {
    AppSnackbar.info(AppStrings.logOut.tr);
    AppNavigator.resetTo(AppRoutes.onboarding);
  }

  // ─── Edit form ───────────────────────────────────────────────────────────
  //
  // Held as plain strings so the inputs own their text controllers.

  final RxString fullName = RiderData.dashboardName.obs;
  final RxString email = RiderData.rider.email.obs;
  final RxString country = RiderData.rider.country.obs;
  final RxString city = RiderData.rider.city.obs;
  final RxString address = RiderData.rider.address.obs;
  final RxString zone = RiderData.zones.first.obs;
  final RxList<String> zones = <String>[].obs;
  final RxBool gpsEnabled = true.obs;

  @override
  void onInit() {
    super.onInit();
    zones.value = List.of(RiderData.pickedZones);
  }

  void selectCountry(String value) => country.value = value;

  void selectCity(String value) => city.value = value;

  void selectZone(String value) {
    zone.value = value;
    if (!zones.contains(value)) zones.add(value);
  }

  void removeZone(String value) => zones.remove(value);

  void toggleGps(bool value) => gpsEnabled.value = value;

  void submit() {
    AppSnackbar.success(AppStrings.shopUpdated.tr);
    Get.back<void>();
  }
}
