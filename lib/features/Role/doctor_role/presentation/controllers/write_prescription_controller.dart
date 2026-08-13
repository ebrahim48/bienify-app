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
  final RxString notes = ''.obs;

  /// How much per dose, and in what. Kept apart from the name so a pharmacy
  /// reads a strength rather than parsing one out of "Amoxicillin500mg".
  final RxString strength = ''.obs;
  final Rx<DoseUnit> unit = DoseUnit.mg.obs;

  /// Doses per day, picked rather than typed — there are only ever a handful.
  final RxInt timesPerDay = 1.obs;

  final Rx<MealTiming> timing = MealTiming.anytime.obs;

  /// The counts the picker offers.
  static const List<int> dailyFrequencies = [1, 2, 3, 4, 5, 6];

  /// Bumped on every save so the form's fields are rebuilt empty — they own
  /// their text controllers, so clearing them means giving them a new key.
  final RxInt formGeneration = 0.obs;

  /// True once at least one line has been saved in this sitting, which is what
  /// reveals "Send to Patient" in the design.
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

  void setStrength(String value) => strength.value = value;

  void setUnit(DoseUnit value) => unit.value = value;

  void setTimesPerDay(int value) => timesPerDay.value = value;

  void setTiming(MealTiming value) => timing.value = value;

  void setNotes(String value) => notes.value = value;

  String timingLabel(MealTiming value) => switch (value) {
    MealTiming.anytime => AppStrings.timingAnytime.tr,
    MealTiming.beforeMeal => AppStrings.timingBeforeMeal.tr,
    MealTiming.afterMeal => AppStrings.timingAfterMeal.tr,
    MealTiming.withFood => AppStrings.timingWithFood.tr,
  };

  /// `500 mg` / `3 times daily` for a line as written; the two seeded lines
  /// carry the design's own wording.
  (String, String) dosageFor(PrescribedMedicine medicine) =>
      DoctorPracticeData.seededDosage[medicine.name] ??
      (
        medicine.doseLabel,
        AppStrings.timesDaily.trParams({'count': '${medicine.timesPerDay}'}),
      );

  void save() {
    final duration = int.tryParse(durationDays.value.trim());

    if (name.value.trim().isEmpty ||
        strength.value.trim().isEmpty ||
        duration == null) {
      AppSnackbar.info(AppStrings.prescriptionNeedsFields.tr);
      return;
    }

    medicines.add(
      PrescribedMedicine(
        name: name.value.trim(),
        strength: strength.value.trim(),
        unit: unit.value,
        durationDays: duration,
        timesPerDay: timesPerDay.value,
        timing: timing.value,
        notes: notes.value.trim(),
      ),
    );

    name.value = '';
    strength.value = '';
    durationDays.value = '';
    notes.value = '';
    // The unit and the schedule are deliberately left where they are: a
    // script is usually several lines of the same shape, and re-picking
    // "mg, 3 times daily, after meals" for each one is needless work.
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
