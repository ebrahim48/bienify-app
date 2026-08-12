import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../patient/medical_vault/domain/entities/medical_record.dart';
import '../../domain/entities/doctor_practice.dart';
import '../../domain/repositories/doctor_practice_repository.dart';

/// Backs the doctor's Appointments tab and the detail behind it.
class DoctorAppointmentsController extends GetxController {
  DoctorAppointmentsController({DoctorPracticeRepository? repository})
    : _repository = repository ?? Get.find<DoctorPracticeRepository>();

  final DoctorPracticeRepository _repository;

  final RxList<DoctorAppointment> appointments = <DoctorAppointment>[].obs;

  final Rx<DoctorApptFilter> filter = DoctorApptFilter.fresh.obs;

  final RxBool isLoading = true.obs;

  /// Set when a load fails, so an empty list is never mistaken for an empty
  /// calendar.
  final RxnString error = RxnString();

  /// Live query from the search field.
  final RxString query = ''.obs;

  /// The row tapped into.
  final Rxn<DoctorAppointment> selected = Rxn<DoctorAppointment>();

  final RxList<UploadedDocument> patientDocuments = <UploadedDocument>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      appointments.value = await _repository.appointments();
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
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

  /// Opening a booking also fetches what the patient shared for it — the list
  /// endpoint does not carry attachments, and loading every patient's
  /// documents to render a list would be a request per row.
  void openDetails(DoctorAppointment appointment) {
    select(appointment);
    Get.toNamed<void>(AppRoutes.doctorAppointmentDetails);
  }

  /// Makes [appointment] the one every screen behind the list reads back.
  ///
  /// Separate from [openDetails] so the detail screen can be reached without
  /// going through the list — the navigation and the selection are two things,
  /// and a screen restored onto a booking still needs its attachments.
  void select(DoctorAppointment appointment) {
    selected.value = appointment;
    patientDocuments.clear();
    // Not awaited: the screen opens on the booking it already has, and the
    // attachment list fills in underneath it.
    _loadDocuments(appointment.id);
  }

  Future<void> _loadDocuments(String appointmentId) async {
    try {
      patientDocuments.value = await _repository.patientDocuments(
        appointmentId,
      );
    } on AppException {
      // The detail screen still shows the booking; an attachment list that
      // could not be read is left empty rather than blocking the screen.
      patientDocuments.clear();
    }
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

  /// Cancels a booking, then moves it under the Cancelled chip.
  ///
  /// The row only moves once the server agrees — cancelling can be refused,
  /// and moving the card first would tell the doctor a consultation was off
  /// when it is still on the patient's calendar.
  Future<void> cancel(DoctorAppointment appointment, String reason) async {
    try {
      await _repository.cancelAppointment(appointment.id, reason: reason);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    }

    final index = appointments.indexWhere((a) => a.id == appointment.id);
    if (index != -1) {
      appointments[index] = DoctorAppointment(
        id: appointment.id,
        patientName: appointment.patientName,
        initials: appointment.initials,
        complaint: appointment.complaint,
        scheduledAt: appointment.scheduledAt,
        filter: DoctorApptFilter.cancelled,
        photoAsset: appointment.photoAsset,
        photoUrl: appointment.photoUrl,
        fee: appointment.fee,
      );
    }
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
