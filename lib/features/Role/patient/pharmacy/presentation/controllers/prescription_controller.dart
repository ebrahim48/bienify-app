import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/services/document_picker_service.dart';
import '../../../../../../core/utils/mime_type.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../medical_vault/domain/entities/medical_record.dart';
import '../../../medical_vault/domain/repositories/vault_repository.dart';
import '../../data/static/pharmacy_mock_data.dart';
import '../../domain/entities/pharmacy.dart';
import '../../domain/repositories/pharmacy_repository.dart';

/// Spans the prescription flow: upload → best matches → medicine selection.
///
/// One controller because all three screens read the same prescription and
/// the chosen pharmacy. The upload is real: the picked file is stored in the
/// patient's medical vault, the same place any other document lands.
class PrescriptionController extends GetxController {
  PrescriptionController({
    PharmacyRepository? repository,
    VaultRepository? vault,
    DocumentPickerService? documentPicker,
  }) : _pharmacy = repository ?? Get.find<PharmacyRepository>(),
       _vault = vault ?? Get.find<VaultRepository>(),
       _documentPicker = documentPicker ?? DocumentPickerService();

  final PharmacyRepository _pharmacy;
  final VaultRepository _vault;
  final DocumentPickerService _documentPicker;

  final Prescription prescription = PharmacyMockData.prescription;
  final String searchArea = PharmacyMockData.searchArea;

  final RxList<PharmacyStore> matches = <PharmacyStore>[].obs;
  final RxnString selectedStoreId = RxnString();
  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  /// Set once a file has been picked, so the upload screen can reflect it.
  final RxnString uploadedFileName = RxnString();
  final RxBool isUploading = false.obs;

  PharmacyStore? get selectedStore =>
      matches.firstWhereOrNull((store) => store.id == selectedStoreId.value);

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    error.value = null;
    try {

      matches.value = await _pharmacy.stores();
      // The best match starts selected, as the design shows.
      selectedStoreId.value = matches.isEmpty ? null : matches.first.id;
    } on AppException catch (e) {
      error.value = e.message;

      final scripts = await _vault.prescriptions();
      // All of them, not just the newest. A patient holding two live scripts
      // had no way to say which one they were filling — the screen matched
      // shops against `scripts.first` and ranked them for a prescription the
      // patient may not have meant.
      prescriptions.value = scripts;
      prescription.value = scripts.isEmpty ? null : scripts.first;

      await _loadMatches();
    } on AppException {
      matches.clear();
    } finally {
      isLoadingMatches.value = false;
    }
  }

  /// Ranks shops against whichever prescription is currently chosen.
  Future<void> _loadMatches() async {
    final script = prescription.value;
    matches.value = script == null
        ? await _pharmacy.stores()
        : await _pharmacy.bestMatches(script.id);

    selectedStoreId.value = matches.isEmpty ? null : matches.first.id;
    searchArea.value = matches.isEmpty ? '' : matches.first.address;
  }

  /// Every prescription the server has issued this patient.
  final RxList<DigitalPrescription> prescriptions = <DigitalPrescription>[].obs;

  /// Whether the patient has more than one to choose between. With one script
  /// there is nothing to pick, and a picker offering a single option is noise.
  bool get hasPrescriptionChoice => prescriptions.length > 1;

  /// Switches which script the shops are ranked against.
  Future<void> selectPrescription(DigitalPrescription script) async {
    if (prescription.value?.id == script.id) return;
    prescription.value = script;

    isLoadingMatches.value = true;
    try {
      await _loadMatches();
    } on AppException {
      matches.clear();

    } finally {
      isLoading.value = false;
    }
  }

  bool isSelected(PharmacyStore store) => selectedStoreId.value == store.id;

  void selectStore(PharmacyStore store) => selectedStoreId.value = store.id;

  Future<void> browseFile() async {
    if (isUploading.value) return;
    final file = await _documentPicker.pick();
    if (file == null) return;

    isUploading.value = true;
    try {
      final fileName = file.path.split('/').last;
      final document = await _vault.uploadDocument(
        bytes: await file.readAsBytes(),
        fileName: fileName,
        contentType: contentTypeForPath(fileName),
        title: 'Prescription — $fileName',
        type: VaultRecordType.prescriptionScan,
      );
      uploadedFileName.value = document.fileName;
      AppSnackbar.success(AppStrings.prescriptionUploaded.tr);
      Get.toNamed<void>(AppRoutes.pharmacyMatches);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      isUploading.value = false;
    }
  }

  void customizeOrder() => Get.toNamed<void>(AppRoutes.selectMedicines);
}
