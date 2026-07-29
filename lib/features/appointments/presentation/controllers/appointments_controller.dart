import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../main/presentation/controllers/main_nav_controller.dart';
import '../../data/static/appointment_mock_data.dart';
import '../../domain/entities/appointment.dart';

/// Backs the Appointments tab.
///
/// UI-only: the roster is static and cancelling/reviewing mutate memory. The
/// grouping and joinable rules are what a backend will later drive.
class AppointmentsController extends GetxController {
  final RxList<Appointment> appointments = <Appointment>[].obs;
  final Rx<AppointmentTab> tab = AppointmentTab.upcoming.obs;
  final RxBool isLoading = true.obs;

  /// A visit can be joined on the day it is scheduled.
  bool isJoinable(Appointment appointment) {
    if (appointment.status != AppointmentStatus.upcoming) return false;
    final now = DateTime.now();
    final at = appointment.scheduledAt;
    return at.year == now.year && at.month == now.month && at.day == now.day;
  }

  List<Appointment> get _visible => switch (tab.value) {
    AppointmentTab.upcoming => appointments
        .where((a) => a.status == AppointmentStatus.upcoming)
        .toList(),
    AppointmentTab.past => appointments
        .where((a) => a.status == AppointmentStatus.completed)
        .toList(),
    AppointmentTab.cancelled => appointments
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
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
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
    await Future<void>.delayed(const Duration(milliseconds: 400));
    appointments.value = AppointmentMockData.all();
    isLoading.value = false;
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

  /// Moves an appointment into the Cancelled tab.
  void cancel(Appointment appointment, String reason) {
    final index = appointments.indexWhere((a) => a.id == appointment.id);
    if (index == -1) return;
    appointments[index] = Appointment(
      id: appointment.id,
      doctorName: appointment.doctorName,
      specialty: appointment.specialty,
      scheduledAt: appointment.scheduledAt,
      status: AppointmentStatus.cancelled,
      doctorPhotoUrl: appointment.doctorPhotoUrl,
    );
    AppSnackbar.success(AppStrings.appointmentCancelled.tr);
  }

  void submitReview(Appointment appointment, int stars) =>
      AppSnackbar.success(AppStrings.reviewSubmitted.tr);
}
