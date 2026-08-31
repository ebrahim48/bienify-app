import '../../domain/repositories/pharmacy_repository.dart';
import '../../../medical_vault/domain/entities/medical_record.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/services/attachment_picker_service.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../chat/presentation/widgets/attachment_sheet.dart';
import '../../../medical_vault/domain/repositories/vault_repository.dart';
import '../../domain/entities/pharmacy.dart';

/// Spans the prescription flow: upload → best matches → medicine selection.
///
/// One controller because all three screens read the same prescription and
/// the chosen pharmacy. The match list is still static — the server has no
/// pharmacy-matching endpoint — but the prescription itself is now really
/// uploaded and filed in the patient's vault.
class PrescriptionController extends GetxController {
  PrescriptionController({
    VaultRepository? vault,
    PharmacyRepository? pharmacy,
    AttachmentPickerService? picker,
  }) : _vault = vault ?? Get.find<VaultRepository>(),
       _pharmacy = pharmacy ?? Get.find<PharmacyRepository>(),
       _picker = picker ?? Get.find<AttachmentPickerService>();

  final VaultRepository _vault;
  final PharmacyRepository _pharmacy;
  final AttachmentPickerService _picker;

  /// The patient's own most recent prescription, once read.
  final Rxn<DigitalPrescription> prescription = Rxn<DigitalPrescription>();

  /// Where the shops shown are. Blank until a search names somewhere — the
  /// screen printed a fixed neighbourhood before.
  final RxString searchArea = ''.obs;

  final RxList<PharmacyStore> matches = <PharmacyStore>[].obs;

  final RxBool isLoadingMatches = true.obs;
  final RxnString selectedStoreId = RxnString();

  /// Set once a file has been picked, so the upload screen can reflect it.
  final RxnString uploadedFileName = RxnString();

  PharmacyStore? get selectedStore =>
      matches.firstWhereOrNull((store) => store.id == selectedStoreId.value);

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  /// Shops that can actually fill the patient's script.
  ///
  /// `GET /pharmacies/best-matches` ranks by how much of a prescription a shop
  /// can dispense, which is the whole point of this screen — it showed three
  /// fixture shops with invented coverage before.
  ///
  /// It needs a prescription the server issued. A photographed paper script is
  /// a vault document with no id to rank against, so that path falls back to
  /// the shops nearby, which is at least true.
  Future<void> _load() async {
    isLoadingMatches.value = true;
    try {
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
      isLoadingMatches.value = false;
    }
  }

  bool isSelected(PharmacyStore store) => selectedStoreId.value == store.id;

  void selectStore(PharmacyStore store) => selectedStoreId.value = store.id;

  /// True while the prescription is being stored.
  final RxBool isUploading = false.obs;

  /// Picks a prescription, files it in the vault, then moves to the matches.
  ///
  /// This used to set the filename to a hardcoded `prescription.pdf` and
  /// navigate on: nothing was picked and nothing was stored, so the pharmacy
  /// on the other end had no prescription to read. A photo of a paper script
  /// is the common case here, which is why the camera is offered.
  Future<void> browseFile(BuildContext context) async {
    if (isUploading.value) return;

    final source = await AttachmentSheet.show(context);
    if (source == null) return;

    isUploading.value = true;
    try {
      final picked = await _picker.pick(source);
      if (picked == null) return;

      await _vault.uploadDocument(
        path: picked.file.path,
        fileName: picked.name,
        mimeType: picked.mime,
        type: VaultRecordType.prescriptionScan,
      );

      uploadedFileName.value = picked.name;
      // Only once it is stored: navigating first is what made the old version
      // look as though it had worked.
      await Get.toNamed<void>(AppRoutes.pharmacyMatches);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      isUploading.value = false;
    }
  }

  void customizeOrder() => Get.toNamed<void>(AppRoutes.selectMedicines);
}
