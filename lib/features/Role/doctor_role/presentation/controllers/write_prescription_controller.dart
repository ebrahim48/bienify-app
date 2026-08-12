import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/utils/app_navigator.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../data/static/doctor_practice_data.dart';
import '../../domain/entities/doctor_practice.dart';
import '../../domain/repositories/doctor_practice_repository.dart';
import 'doctor_appointments_controller.dart';

/// Backs Write Prescriptions: the lines already written, and the form that
/// adds another.
///
/// The script is filed against the consultation the doctor came in from, which
/// is the appointment selected on the Appointments tab — `POST
/// /consultations/:id/prescriptions` is keyed by it.
///
/// Field values are plain strings so the inputs own their text controllers.
class WritePrescriptionController extends GetxController {
  WritePrescriptionController({DoctorPracticeRepository? repository})
    : _repository = repository ?? Get.find<DoctorPracticeRepository>();

  final DoctorPracticeRepository _repository;

  final RxList<PrescribedMedicine> medicines = <PrescribedMedicine>[].obs;

  final RxBool isSubmitting = false.obs;

  /// Whether the form under "Add New Medicine" is showing.
  final RxBool isFormOpen = true.obs;

  final RxString name = ''.obs;
  final RxString durationDays = ''.obs;
  final RxString dailyDose = ''.obs;
  final RxString instructions = ''.obs;

  /// Bumped on every save so the form's fields are rebuilt empty — they own
  /// their text controllers, so clearing them means giving them a new key.
  final RxInt formGeneration = 0.obs;

  /// True once at least one line has been saved in this sitting, which is what
  /// reveals "Submit Your patients" in the design.
  final RxBool hasSaved = false.obs;

  /// A new script starts empty — the lines in the design are a filled-in
  /// example, not a default every patient is prescribed.
  @override
  void onInit() {
    super.onInit();
  }

  void openForm() => isFormOpen.value = true;

  void setName(String value) => name.value = value;

  void setDuration(String value) => durationDays.value = value;

  void setDose(String value) => dailyDose.value = value;

  void setInstructions(String value) => instructions.value = value;

  /// `1 capsule` / `3 times daily` for the two seeded lines, which carry the
  /// design's wording; anything written here prints its own numbers.
  (String, String) dosageFor(PrescribedMedicine medicine) =>
      DoctorPracticeData.seededDosage[medicine.name] ??
      (
        medicine.doseLabel,
        AppStrings.timesDaily.trParams({'count': '${medicine.dailyDose}'}),
      );

  void save() {
    final duration = int.tryParse(durationDays.value.trim());
    final dose = int.tryParse(dailyDose.value.trim());

    if (name.value.trim().isEmpty || duration == null || dose == null) {
      AppSnackbar.info(AppStrings.prescriptionNeedsFields.tr);
      return;
    }

    medicines.add(
      PrescribedMedicine(
        name: name.value.trim(),
        durationDays: duration,
        dailyDose: dose,
        instructions: instructions.value.trim(),
      ),
    );

    name.value = '';
    durationDays.value = '';
    dailyDose.value = '';
    instructions.value = '';
    formGeneration.value++;
    hasSaved.value = true;
    AppSnackbar.success(AppStrings.medicineAdded.tr);
  }

  void removeMedicine(PrescribedMedicine medicine) =>
      medicines.remove(medicine);

  /// Sending the script to the patient ends the consultation for the doctor.
  ///
  /// Refuses an empty script and a missing consultation rather than posting
  /// either — the server would reject both, and its validation message would
  /// not say which of the two the doctor has to fix.
  Future<void> submit() async {
    if (isSubmitting.value) return;

    if (medicines.isEmpty) {
      AppSnackbar.info(AppStrings.prescriptionNeedsFields.tr);
      return;
    }

    final appointmentId = Get.isRegistered<DoctorAppointmentsController>()
        ? Get.find<DoctorAppointmentsController>().selected.value?.id
        : null;
    if (appointmentId == null || appointmentId.isEmpty) {
      AppSnackbar.info(AppStrings.prescriptionNeedsAppointment.tr);
      return;
    }

    isSubmitting.value = true;
    try {
      await _repository.prescribe(
        appointmentId: appointmentId,
        medicines: medicines.toList(),
      );
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    } finally {
      isSubmitting.value = false;
    }

    AppSnackbar.success(AppStrings.prescriptionSent.tr);
    AppNavigator.resetTo(AppRoutes.doctorHome);
  }
}
