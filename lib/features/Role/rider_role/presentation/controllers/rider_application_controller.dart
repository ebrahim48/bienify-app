import 'dart:io';

import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../data/static/rider_data.dart';
import '../../domain/entities/rider.dart';

/// Backs the five-step application behind Apply Now.
///
/// One controller and one screen for all of it: the designs are the same
/// page with a different body and the same progress bar, so the step decides
/// what is on it.
class RiderApplicationController extends GetxController {
  static const int stepCount = 5;

  final RxInt step = 0.obs;

  /// The photos, held as files because they are real captures rather than
  /// asset names.
  final Rxn<File> selfie = Rxn<File>();
  final Rxn<File> idFront = Rxn<File>();
  final Rxn<File> idBack = Rxn<File>();
  final Rxn<File> licence = Rxn<File>();
  final Rxn<File> vehiclePhoto = Rxn<File>();

  final Rx<VehicleType> vehicle = VehicleType.bike.obs;

  final RxString country = RiderData.countries.first.obs;
  final RxString city = RiderData.cities.first.obs;
  final RxString address = RiderData.rider.address.obs;
  final RxString zone = RiderData.zones.first.obs;
  final RxList<String> zones = <String>[].obs;
  final RxBool gpsEnabled = true.obs;

  /// Whether a payment method has been added on the last step.
  final RxBool hasPaymentMethod = false.obs;

  @override
  void onInit() {
    super.onInit();
    zones.value = List.of(RiderData.pickedZones);
  }

  String get title => switch (step.value) {
    0 => AppStrings.uploadProfileTitle.tr,
    1 => AppStrings.identityVerification.tr,
    2 => AppStrings.vehicleInformation.tr,
    3 => AppStrings.locationAndAvailability.tr,
    _ => AppStrings.paymentSetup.tr,
  };

  /// Every starred photo has to be there before the step will advance. The
  /// selfie and the payment method are not starred in the designs, so those
  /// steps let the courier past.
  bool get canContinue => switch (step.value) {
    1 => idFront.value != null && idBack.value != null,
    2 => licence.value != null && vehiclePhoto.value != null,
    _ => true,
  };

  bool get isLastStep => step.value == stepCount - 1;

  void selectVehicle(VehicleType value) => vehicle.value = value;

  void selectCountry(String value) => country.value = value;

  void selectCity(String value) => city.value = value;

  /// Picking a zone adds it to the chips rather than replacing the last one.
  void selectZone(String value) {
    zone.value = value;
    if (!zones.contains(value)) zones.add(value);
  }

  void removeZone(String value) => zones.remove(value);

  void toggleGps(bool value) => gpsEnabled.value = value;

  void addPaymentMethod() {
    hasPaymentMethod.value = true;
    Get.toNamed<void>(AppRoutes.paymentOptions);
  }

  void next() {
    if (!canContinue) {
      AppSnackbar.info(AppStrings.photoNeeded.tr);
      return;
    }
    if (isLastStep) {
      submit();
      return;
    }
    step.value++;
  }

  /// Steps back through the application before leaving it, so the chevron
  /// walks the flow rather than dropping out of it.
  bool stepBack() {
    if (step.value == 0) return false;
    step.value--;
    return true;
  }

  void submit() => Get.offNamed<void>(AppRoutes.riderReady);
}
