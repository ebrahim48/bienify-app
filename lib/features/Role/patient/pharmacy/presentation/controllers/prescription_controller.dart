import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/services/attachment_picker_service.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../chat/presentation/widgets/attachment_sheet.dart';
import '../../../medical_vault/domain/repositories/vault_repository.dart';
import '../../data/static/pharmacy_mock_data.dart';
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
    AttachmentPickerService? picker,
  }) : _vault = vault ?? Get.find<VaultRepository>(),
       _picker = picker ?? Get.find<AttachmentPickerService>();

  final VaultRepository _vault;
  final AttachmentPickerService _picker;

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
