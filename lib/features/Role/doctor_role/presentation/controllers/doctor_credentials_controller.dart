import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/network/mappers.dart';
import '../../../../../core/services/attachment_picker_service.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../patient/chat/presentation/widgets/attachment_sheet.dart';
import '../../domain/entities/doctor_practice.dart';
import '../../domain/repositories/doctor_practice_repository.dart';

/// Backs the practitioner's credentials screen.
///
/// The endpoints existed with no caller: `POST /doctors/me/credentials`
/// demanded a key under the doctor's own prefix and nothing issued one, so
/// submitting a licence was unreachable through the API. The upload-url half
/// was added earlier; this is the screen that finally uses both.
class DoctorCredentialsController extends GetxController {
  DoctorCredentialsController({
    DoctorPracticeRepository? repository,
    AttachmentPickerService? picker,
  }) : _repository = repository ?? Get.find<DoctorPracticeRepository>(),
       _picker = picker ?? Get.find<AttachmentPickerService>();

  final DoctorPracticeRepository _repository;
  final AttachmentPickerService _picker;

  /// What a document can be filed as. Free text server-side; a fixed list here
  /// so two doctors do not file the same paper under two names.
  static const List<String> kinds = [
    'medical_licence',
    'board_certificate',
    'identity',
    'other',
  ];

  final RxList<PractitionerCredential> credentials =
      <PractitionerCredential>[].obs;

  final RxString verificationStatus = 'pending'.obs;
  final RxString verificationNote = ''.obs;

  final RxString kind = kinds.first.obs;

  final RxBool isLoading = true.obs;
  final RxBool isUploading = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final details = await _repository.profileDetails();
      credentials.value = List.of(details.credentials);
      verificationStatus.value = details.verificationStatus;
      verificationNote.value = details.verificationNote;
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      isLoading.value = false;
    }
  }

  void selectKind(String value) => kind.value = value;

  /// Picks a document and files it against the practitioner's profile.
  ///
  /// A photograph of a paper licence is the common case, which is why the
  /// camera is offered alongside the file picker.
  Future<void> addCredential(BuildContext context) async {
    if (isUploading.value) return;

    final source = await AttachmentSheet.show(context);
    if (source == null) return;

    isUploading.value = true;
    try {
      final picked = await _picker.pick(source);
      if (picked == null) return;

      await _repository.uploadCredential(
        kind: kind.value,
        path: picked.file.path,
        mimeType: picked.mime,
      );

      // Re-read rather than appending locally: filing a credential moves a
      // *rejected* profile back to pending, so the banner above may change.
      // An approved profile stays approved — extra evidence is additive, and
      // un-verifying a working doctor for submitting a certificate would take
      // them out of search and stop them earning.
      await load();
      AppSnackbar.success(AppStrings.credentialAdded.tr);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      isUploading.value = false;
    }
  }

  static String kindLabel(String kind) => switch (kind) {
    'medical_licence' => AppStrings.medicalLicence.tr,
    'board_certificate' => AppStrings.boardCertificate.tr,
    'identity' => AppStrings.identityDocument.tr,
    _ => AppStrings.otherDocument.tr,
  };

  static String uploadedLabel(DateTime at) =>
      AppStrings.uploadedOn.trParams({'date': formatDate(at)});
}
