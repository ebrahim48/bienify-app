import 'dart:io';

import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../data/static/rider_data.dart';
import '../../domain/entities/rider.dart';
import '../../../patient/profile/domain/repositories/account_repository.dart';
import '../../domain/repositories/rider_repository.dart';

/// Backs the five-step application behind Apply Now.
///
/// One controller and one screen for all of it: the designs are the same
/// page with a different body and the same progress bar, so the step decides
/// what is on it.
class RiderApplicationController extends GetxController {
  RiderApplicationController({RiderRepository? repository})
    : _repository = repository ?? Get.find<RiderRepository>();

  final RiderRepository _repository;

  static const int stepCount = 5;

  final RxBool isSubmitting = false.obs;

  /// The licence number the courier rides under. Plain string so the input
  /// owns its text controller.
  final RxString licenceNumber = ''.obs;

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

  /// Typed by the applicant. It was pre-filled with the sample courier's
  /// street, so a courier who never touched the field applied from an address
  /// that was not theirs.
  final RxString address = ''.obs;
  final RxString zone = RiderData.zones.first.obs;

  /// The applicant's own first name, for the greeting.
  final RxString firstName = ''.obs;
  final RxList<String> zones = <String>[].obs;
  final RxBool gpsEnabled = true.obs;

  /// Whether a payment method has been added on the last step.
  final RxBool hasPaymentMethod = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Nothing pre-selected: the zones a courier covers are their choice, and
    // the fixture picked three on their behalf.
    zones.value = <String>[];
    _loadApplicant();
  }

  /// The signed-in account's first name, for the greeting on step one.
  Future<void> _loadApplicant() async {
    try {
      final me = await Get.find<AccountRepository>().me();
      firstName.value = me.name.split(' ').first;
    } on AppException {
      // The greeting simply omits the name; it is a nicety, not the flow.
      firstName.value = '';
    }
  }

  String get title => switch (step.value) {
    0 => AppStrings.uploadProfileTitle.tr,
    1 => AppStrings.identityVerification.tr,
    2 => AppStrings.vehicleInformation.tr,
    3 => AppStrings.locationAndAvailability.tr,
    _ => AppStrings.paymentSetup.tr,
  };

  /// The shortest licence number the server will store.
  static const int _minLicenceLength = 3;

  /// Every starred photo has to be there before the step will advance. The
  /// selfie and the payment method are not starred in the designs, so those
  /// steps let the courier past.
  ///
  /// The licence number is checked here rather than at the end: it is the one
  /// field the server insists on, and finding that out after five steps of
  /// photographs is no way to learn it.
  bool get canContinue => switch (step.value) {
    1 => idFront.value != null && idBack.value != null,
    2 =>
      licence.value != null &&
          vehiclePhoto.value != null &&
          licenceNumber.value.trim().length >= _minLicenceLength,
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
      // Say which of the two is missing: "add a photo" is unhelpful advice to
      // a courier who has taken both and left the number blank.
      final needsLicenceNumber =
          step.value == 2 &&
          licenceNumber.value.trim().length < _minLicenceLength;
      AppSnackbar.info(
        needsLicenceNumber
            ? AppStrings.licenceNumberNeeded.tr
            : AppStrings.photoNeeded.tr,
      );
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

  /// Files the application, documents included.
  ///
  /// The photos used to be captured and then dropped on the floor: the profile
  /// fields were sent and the five images never left the phone, because
  /// `POST /riders/me/documents` wants a key under the courier's own prefix and
  /// nothing issued one. With the upload-url endpoint in place they are sent
  /// here, after the profile exists — the documents attach to a rider record,
  /// so there has to be one first.
  ///
  /// A failed photo does not fail the application. The profile is already
  /// filed at that point, and telling a courier their whole application was
  /// lost because one of five uploads timed out would be false; they are told
  /// which ones to add again instead.
  Future<void> submit() async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      await _repository.apply(
        vehicleType: serverVehicleType(vehicle.value),
        licenceNumber: licenceNumber.value.trim(),
        city: city.value,
      );
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    } finally {
      isSubmitting.value = false;
    }

    final failed = await _uploadDocuments();
    if (failed.isNotEmpty) {
      AppSnackbar.info(AppStrings.someDocumentsNotSent.tr);
    }
    Get.offNamed<void>(AppRoutes.riderReady);
  }

  /// Sends every captured photo; returns the kinds that did not make it.
  Future<List<String>> _uploadDocuments() async {
    final documents = <String, File?>{
      'selfie': selfie.value,
      'id_front': idFront.value,
      'id_back': idBack.value,
      'licence': licence.value,
      'vehicle': vehiclePhoto.value,
    };

    final failed = <String>[];
    for (final entry in documents.entries) {
      final file = entry.value;
      if (file == null) continue;
      try {
        await _repository.uploadDocument(
          kind: entry.key,
          path: file.path,
          mimeType: _mimeOf(file.path),
        );
      } on AppException {
        failed.add(entry.key);
      }
    }
    return failed;
  }

  /// The picker hands back whatever the camera or gallery produced; the server
  /// only signs the four types it accepts, so anything else is sent as JPEG,
  /// which is what a phone camera actually produces.
  static String _mimeOf(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'image/jpeg';
  }

  /// The picker offers three vehicles and the server names four; `bike` is
  /// its `motorbike`.
  static String serverVehicleType(VehicleType value) => switch (value) {
    VehicleType.bicycle => 'bicycle',
    VehicleType.bike => 'motorbike',
    VehicleType.car => 'car',
  };
}
