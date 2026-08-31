import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/routes/app_routes.dart';

import '../../../../../../core/services/document_picker_service.dart';
import '../../../../../../core/utils/mime_type.dart';

import '../../../../../../core/services/account_deletion_service.dart';
import '../../../../../../core/services/support_service.dart';

import '../../../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/medical_record.dart';
import '../../domain/repositories/vault_repository.dart';

/// Backs My Health Profile and the two record lists behind it.
class DocumentsController extends GetxController {
  DocumentsController({
    VaultRepository? repository,
    DocumentPickerService? documentPicker,
    SupportService? support,
    AccountDeletionService? deletion,
  }) : _repository = repository ?? Get.find<VaultRepository>(),
       _documentPicker = documentPicker ?? DocumentPickerService(),
       _support = support ?? SupportService(),
       _deletion = deletion ?? AccountDeletionService();

  final VaultRepository _repository;
  final DocumentPickerService _documentPicker;
  final SupportService _support;
  final AccountDeletionService _deletion;

  final RxBool isLoading = true.obs;

  /// True while a picked file is uploading, so the button can say so and a
  /// second tap cannot start a parallel upload.
  final RxBool isUploading = false.obs;

  /// Set when the vault cannot be read. An empty history and an unreachable
  /// server look identical on screen unless one of them says so.
  final RxnString error = RxnString();
  final RxList<DigitalPrescription> prescriptions = <DigitalPrescription>[].obs;

  final RxList<UploadedDocument> uploads = <UploadedDocument>[].obs;

  /// Which tab All Prescriptions is showing.
  final Rx<PrescriptionSource> source = PrescriptionSource.uploads.obs;

  /// Which tab All Test Reports is showing. The design lists the same records
  /// under both, so this only drives the pill.
  final Rx<ResultDiscipline> discipline = ResultDiscipline.laboratory.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      prescriptions.value = await _repository.prescriptions();
      uploads.value = await _repository.documents();
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Health profile tiles ────────────────────────────────────────────────

  void openPrescriptions() => Get.toNamed<void>(AppRoutes.allPrescriptions);

  void openTestReports() => Get.toNamed<void>(AppRoutes.allTestReports);

  void openPastAppointments() => Get.toNamed<void>(AppRoutes.pastAppointments);

  void openTestsAndResults() => Get.toNamed<void>(AppRoutes.testResults);

  void openOrderHistory() => Get.toNamed<void>(AppRoutes.orderHistory);

  /// Writes to the support address the platform publishes.
  ///
  /// It used to open the chat screen against `bienify-support` — an account
  /// that exists nowhere. With no appointment behind it the thread ran in
  /// local mode, so a patient typed their problem, received a canned reply
  /// 900ms later, and believed support had answered. Nobody was reading it.
  /// A mail composer addressed to a real inbox is a channel that exists.
  Future<void> openSupportChat() => _support.openChat();

  /// Dials the published support number.
  Future<void> callSupport() => _support.call();

  /// Confirmed in the screen first, then actually closed on the server.
  Future<void> deleteAccount() => _deletion.deleteAccount();

  // ─── All Prescriptions ───────────────────────────────────────────────────

  void selectSource(PrescriptionSource value) => source.value = value;

  String sourceLabel(PrescriptionSource value) => switch (value) {
    PrescriptionSource.uploads => AppStrings.yourPrescriptions.tr,
    PrescriptionSource.medicalVault => AppStrings.yourMedicalVault.tr,
  };

  /// `Digital Prescription 01` — the position in the list, not the reference.
  String numberedLabel(int index) => AppStrings.digitalPrescriptionNumbered
      .trParams({'number': '${index + 1}'.padLeft(2, '0')});

  void openPrescription(DigitalPrescription prescription) =>
      Get.toNamed<void>(AppRoutes.prescriptionDetails, arguments: prescription);

  /// Files a document the patient picked off their phone.
  ///
  /// This used to append another copy of the sample upload, so the list grew
  /// by one every tap and nothing ever reached the vault. The record the
  /// server creates is what goes into [uploads] — not a locally invented one,
  /// which would carry an id no later removal could match.
  Future<void> uploadPrescription() async {
    if (isUploading.value) return;

    final file = await _documentPicker.pick();
    if (file == null) return;

    isUploading.value = true;
    try {
      final fileName = file.path.split('/').last;
      final document = await _repository.uploadDocument(
        path: file.path,
        fileName: fileName,
        mimeType: contentTypeForPath(fileName),
        type: VaultRecordType.other,
      );
      uploads.insert(0, document);
      AppSnackbar.success(AppStrings.documentUploaded.tr);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      isUploading.value = false;
    }
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

  /// `March 31, 2026` — hand-formatted, matching the other date labels.
  String issuedLabel(DateTime at) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[at.month - 1]} ${at.day}, ${at.year}';
  }

  /// `Apr 3, 2026` — the shorter form the upload card uses.
  String shortDateLabel(DateTime at) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[at.month - 1]} ${at.day}, ${at.year}';
  }
}
