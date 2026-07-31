import 'package:get/get.dart';

import '../../../../../../core/routes/app_routes.dart';
import '../../data/static/pharmacy_mock_data.dart';
import '../../domain/entities/pharmacy.dart';

/// Spans the prescription flow: upload → best matches → medicine selection.
///
/// One controller because all three screens read the same prescription and
/// the chosen pharmacy. UI-only: no upload happens, and the match list is
/// static.
class PrescriptionController extends GetxController {
  final Prescription prescription = PharmacyMockData.prescription;
  final String searchArea = PharmacyMockData.searchArea;

  final RxList<PharmacyStore> matches = <PharmacyStore>[].obs;
  final RxnString selectedStoreId = RxnString();

  /// Set once a file has been picked, so the upload screen can reflect it.
  final RxnString uploadedFileName = RxnString();

  PharmacyStore? get selectedStore =>
      matches.firstWhereOrNull((store) => store.id == selectedStoreId.value);

  @override
  void onInit() {
    super.onInit();
    matches.value = PharmacyMockData.matches;
    // The best match starts selected, as the design shows.
    selectedStoreId.value = matches.first.id;
  }

  bool isSelected(PharmacyStore store) => selectedStoreId.value == store.id;

  void selectStore(PharmacyStore store) => selectedStoreId.value = store.id;

  /// File picking needs a platform plugin; until one is wired the flow
  /// continues with the sample prescription so the journey stays walkable.
  void browseFile() {
    uploadedFileName.value = 'prescription.pdf';
    Get.toNamed<void>(AppRoutes.pharmacyMatches);
  }

  void customizeOrder() => Get.toNamed<void>(AppRoutes.selectMedicines);
}
