import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../chat/data/static/chat_mock_data.dart';
import '../../data/static/medical_mock_data.dart';
import '../../domain/entities/medical_record.dart';

/// Backs My Health Profile and the two record lists behind it.
///
/// UI-only — everything comes from [MedicalMockData] and nothing calls an API.
class DocumentsController extends GetxController {
  final RxList<DigitalPrescription> prescriptions =
      <DigitalPrescription>[].obs;

  final RxList<UploadedDocument> uploads = <UploadedDocument>[].obs;

  /// Which tab All Prescriptions is showing.
  final Rx<PrescriptionSource> source = PrescriptionSource.uploads.obs;

  /// Which tab All Test Reports is showing. The design lists the same records
  /// under both, so this only drives the pill.
  final Rx<ResultDiscipline> discipline = ResultDiscipline.laboratory.obs;

  @override
  void onInit() {
    super.onInit();
    prescriptions.value = MedicalMockData.prescriptions();
    uploads.value = List.of(MedicalMockData.uploads());
  }

  // ─── Health profile tiles ────────────────────────────────────────────────

  void openPrescriptions() => Get.toNamed<void>(AppRoutes.allPrescriptions);

  void openTestReports() => Get.toNamed<void>(AppRoutes.allTestReports);

  void openPastAppointments() =>
      Get.toNamed<void>(AppRoutes.pastAppointments);

  void openTestsAndResults() => Get.toNamed<void>(AppRoutes.testResults);

  void openOrderHistory() => Get.toNamed<void>(AppRoutes.orderHistory);

  /// Support reuses the existing chat screen, with Bienify as the peer.
  void openSupportChat() =>
      Get.toNamed<void>(AppRoutes.chat, arguments: ChatMockData.support);

  /// UI-only: placing a real call is a marked seam.
  void callSupport() => AppSnackbar.info(AppStrings.callWithUs.tr);

  /// UI-only: account deletion is a marked seam, so this acknowledges it.
  void deleteAccount() => AppSnackbar.info(AppStrings.deleteAccount.tr);

  // ─── All Prescriptions ───────────────────────────────────────────────────

  void selectSource(PrescriptionSource value) => source.value = value;

  String sourceLabel(PrescriptionSource value) => switch (value) {
    PrescriptionSource.uploads => AppStrings.yourPrescriptions.tr,
    PrescriptionSource.medicalVault => AppStrings.yourMedicalVault.tr,
  };

  /// `Digital Prescription 01` — the position in the list, not the reference.
  String numberedLabel(int index) =>
      AppStrings.digitalPrescriptionNumbered.trParams({
        'number': '${index + 1}'.padLeft(2, '0'),
      });

  void openPrescription(DigitalPrescription prescription) => Get.toNamed<void>(
    AppRoutes.prescriptionDetails,
    arguments: prescription,
  );

  /// UI-only: file capture is a marked seam, so this adds a further copy of
  /// the sample upload rather than opening a picker.
  void uploadPrescription() {
    final next = uploads.length + 1;
    uploads.add(
      UploadedDocument(
        id: 'upload-$next',
        fileName: 'image ($next).png',
        kindLabel: AppStrings.labResult.tr,
        uploadedOn: DateTime(2026, 4, 3),
      ),
    );
  }

  void removeUpload(UploadedDocument document) {
    uploads.removeWhere((u) => u.id == document.id);
    AppSnackbar.info(AppStrings.documentRemoved.tr);
  }

  /// Viewing an upload opens the report screen, which is what renders a
  /// document image today.
  void viewUpload(UploadedDocument document) =>
      Get.toNamed<void>(AppRoutes.reportReview);

  // ─── All Test Reports ────────────────────────────────────────────────────

  void selectDiscipline(ResultDiscipline value) => discipline.value = value;

  String disciplineLabel(ResultDiscipline value) => switch (value) {
    ResultDiscipline.laboratory => AppStrings.labReports.tr,
    ResultDiscipline.radiology => AppStrings.radiologyReports.tr,
  };

  // ─── Prescription detail ─────────────────────────────────────────────────

  /// UI-only: PDF export is a marked seam, so this acknowledges the tap.
  void download(DigitalPrescription prescription) =>
      AppSnackbar.info(AppStrings.downloadPrescription.tr);

  /// `March 31, 2026` — hand-formatted, matching the other date labels.
  String issuedLabel(DateTime at) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[at.month - 1]} ${at.day}, ${at.year}';
  }

  /// `Apr 3, 2026` — the shorter form the upload card uses.
  String shortDateLabel(DateTime at) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[at.month - 1]} ${at.day}, ${at.year}';
  }
}
