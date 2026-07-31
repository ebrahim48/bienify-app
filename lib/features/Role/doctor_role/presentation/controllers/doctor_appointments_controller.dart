import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../patient/medical_vault/domain/entities/medical_record.dart';
import '../../data/static/doctor_practice_data.dart';
import '../../domain/entities/doctor_practice.dart';

/// Backs the doctor's Appointments tab and the detail behind it.
///
/// UI-only — the roster comes from [DoctorPracticeData] and cancelling only
/// moves a row between chips.
class DoctorAppointmentsController extends GetxController {
  final RxList<DoctorAppointment> appointments = <DoctorAppointment>[].obs;

  final Rx<DoctorApptFilter> filter = DoctorApptFilter.fresh.obs;

  /// Live query from the search field.
  final RxString query = ''.obs;

  /// The row tapped into.
  final Rxn<DoctorAppointment> selected = Rxn<DoctorAppointment>();

  final RxList<UploadedDocument> patientDocuments = <UploadedDocument>[].obs;

  @override
  void onInit() {
    super.onInit();
    appointments.value = DoctorPracticeData.appointments();
    patientDocuments.value = DoctorPracticeData.patientDocuments();
  }

  // ─── List ────────────────────────────────────────────────────────────────

  List<DoctorAppointment> get visible {
    final search = query.value.trim().toLowerCase();
    return appointments
        .where((appointment) => appointment.filter == filter.value)
        .where(
          (appointment) =>
              search.isEmpty ||
              appointment.patientName.toLowerCase().contains(search) ||
              appointment.complaint.toLowerCase().contains(search),
        )
        .toList();
  }

  void selectFilter(DoctorApptFilter value) => filter.value = value;

  String filterLabel(DoctorApptFilter value) => switch (value) {
    DoctorApptFilter.fresh => AppStrings.newAppointment.tr,
    DoctorApptFilter.completed => AppStrings.completedAppointment.tr,
    DoctorApptFilter.cancelled => AppStrings.cancelledAppointmentTab.tr,
  };

  /// The pill on a card, which is shorter than the chip above the list —
  /// "Completed", not "Completed Appointment", so the patient's name keeps
  /// its room.
  String cardStatusLabel(DoctorApptFilter value) => switch (value) {
    DoctorApptFilter.fresh => AppStrings.newAppointment.tr,
    DoctorApptFilter.completed => AppStrings.completed.tr,
    DoctorApptFilter.cancelled => AppStrings.filterCancelled.tr,
  };

  // ─── Actions ─────────────────────────────────────────────────────────────

  void openDetails(DoctorAppointment appointment) {
    selected.value = appointment;
    Get.toNamed<void>(AppRoutes.doctorAppointmentDetails);
  }

  /// Only the visit whose room is open can be joined; the others show a muted
  /// Join and say why rather than doing nothing.
  void join(DoctorAppointment appointment) {
    if (!appointment.isJoinable) {
      AppSnackbar.info(AppStrings.roomNotOpenYet.tr);
      return;
    }
    selected.value = appointment;
    Get.toNamed<void>(AppRoutes.doctorVideoCall);
  }

  /// Moves a booking under the Cancelled chip. The reason comes from the
  /// appointments feature's own `CancelReasonDialog`.
  void cancel(DoctorAppointment appointment, String reason) {
    final index = appointments.indexWhere((a) => a.id == appointment.id);
    if (index == -1) return;
    appointments[index] = DoctorAppointment(
      id: appointment.id,
      patientName: appointment.patientName,
      complaint: appointment.complaint,
      scheduledAt: appointment.scheduledAt,
      filter: DoctorApptFilter.cancelled,
      photoAsset: appointment.photoAsset,
    );
    AppSnackbar.success(AppStrings.appointmentCancelled.tr);
  }

  void writePrescription() =>
      Get.toNamed<void>(AppRoutes.doctorWritePrescription);

  /// Viewing a patient's attachment opens the report screen, which is what
  /// renders a document image today.
  void viewDocument(UploadedDocument document) =>
      Get.toNamed<void>(AppRoutes.reportReview);

  void removeDocument(UploadedDocument document) {
    patientDocuments.removeWhere((d) => d.id == document.id);
    AppSnackbar.info(AppStrings.documentRemoved.tr);
  }

  /// `Apr 3, 2026`.
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
