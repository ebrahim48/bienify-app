import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../main/presentation/controllers/main_nav_controller.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';

/// Backs the Appointments tab.
///
/// The roster comes from an [AppointmentRepository]; the grouping and joinable
/// rules are this controller's own.
class AppointmentsController extends GetxController {
  AppointmentsController({
    DateTime Function() clock = DateTime.now,
    AppointmentRepository? repository,
  }) : _clock = clock,
       _repository = repository ?? Get.find<AppointmentRepository>();

  /// Injectable so goldens can pin "today"; production uses the wall clock.
  final DateTime Function() _clock;

  final AppointmentRepository _repository;

  /// Set when a load fails, so the screen can say what went wrong rather than
  /// showing an empty list that reads as "you have no appointments".
  final RxnString error = RxnString();

  final RxList<Appointment> appointments = <Appointment>[].obs;
  final Rx<AppointmentTab> tab = AppointmentTab.upcoming.obs;
  final RxBool isLoading = true.obs;

  /// A visit can be joined on the day it is scheduled.
  bool isJoinable(Appointment appointment) {
    if (appointment.status != AppointmentStatus.upcoming) return false;
    final now = _clock();
    final at = appointment.scheduledAt;
    return at.year == now.year && at.month == now.month && at.day == now.day;
  }

  List<Appointment> get _visible => switch (tab.value) {
    AppointmentTab.upcoming =>
      appointments
          .where((a) => a.status == AppointmentStatus.upcoming)
          .toList(),
    AppointmentTab.past =>
      appointments
          .where((a) => a.status == AppointmentStatus.completed)
          .toList(),
    AppointmentTab.cancelled =>
      appointments
          .where((a) => a.status == AppointmentStatus.cancelled)
          .toList(),
  };

  /// Upcoming appointments are filed under date headings; the other tabs are
  /// a flat list, matching the design.
  List<AppointmentGroup> get groups {
    final items = _visible;
    if (tab.value != AppointmentTab.upcoming) {
      return [AppointmentGroup(label: '', items: items)];
    }

    final byLabel = <String, List<Appointment>>{};
    for (final appointment in items) {
      byLabel.putIfAbsent(_groupLabel(appointment), () => []).add(appointment);
    }
    return [
      for (final entry in byLabel.entries)
        AppointmentGroup(label: entry.key, items: entry.value),
    ];
  }

  /// `Today` for today's date, otherwise `23 February`.
  String _groupLabel(Appointment appointment) {
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
    if (isJoinable(appointment)) return AppStrings.today.tr;
    final at = appointment.scheduledAt;
    return '${at.day} ${months[at.month - 1]}';
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      appointments.value = await _repository.list();
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  void selectTab(AppointmentTab value) => tab.value = value;

  bool isSelected(AppointmentTab value) => tab.value == value;

  // ─── Actions ─────────────────────────────────────────────────────────────

  void join(Appointment appointment) =>
      Get.toNamed<void>(AppRoutes.videoCall, arguments: appointment);

  /// Booking and re-booking both start at the doctor directory.
  void bookAppointment() => Get.find<MainNavController>().select(2);

  void bookAgain(Appointment appointment) => bookAppointment();

  void reschedule(Appointment appointment) => bookAppointment();

  /// Cancels [appointment] and moves it into the Cancelled tab.
  ///
  /// The list is only updated after the server agrees. Moving the card first
  /// would tell the patient a consultation was cancelled when it may still be
  /// on the doctor's calendar — and cancelling can genuinely be refused, for
  /// instance once the consultation has started.
  Future<void> cancel(Appointment appointment, String reason) async {
    try {
      await _repository.cancel(appointment.id, reason: reason);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    }

    final index = appointments.indexWhere((a) => a.id == appointment.id);
    if (index != -1) {
      appointments[index] = Appointment(
        id: appointment.id,
        doctorName: appointment.doctorName,
        specialty: appointment.specialty,
        scheduledAt: appointment.scheduledAt,
        status: AppointmentStatus.cancelled,
        doctorPhotoUrl: appointment.doctorPhotoUrl,
      );
    }
    AppSnackbar.success(AppStrings.appointmentCancelled.tr);
  }

  Future<void> submitReview(Appointment appointment, int stars) async {
    try {
      await _repository.review(appointmentId: appointment.id, rating: stars);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    }
    AppSnackbar.success(AppStrings.reviewSubmitted.tr);
  }
}
