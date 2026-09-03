import 'dart:async';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/services/call_service.dart';
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

  /// A visit can be joined on the day it is scheduled — but never one still
  /// awaiting payment. That used to fall through this check by accident,
  /// since an unpaid booking and a confirmed one were the same status; the
  /// server was the only thing that ever caught it, after the patient tapped
  /// a "Join Visit" button that was never going to work.
  bool isJoinable(Appointment appointment) {
    if (appointment.status != AppointmentStatus.upcoming) return false;
    final now = _clock();
    final at = appointment.scheduledAt;
    return at.year == now.year && at.month == now.month && at.day == now.day;
  }

  bool needsPayment(Appointment appointment) =>
      appointment.status == AppointmentStatus.pendingPayment;

  List<Appointment> get _visible => switch (tab.value) {
    // An unpaid booking is still something to act on, not history — it stays
    // in Upcoming, with Pay Now standing in for Join until it clears.
    AppointmentTab.upcoming =>
      appointments
          .where(
            (a) =>
                a.status == AppointmentStatus.upcoming ||
                a.status == AppointmentStatus.pendingPayment,
          )
          .toList(),
    // A lapsed consultation belongs with history, not with cancellations —
    // nobody called it off, so filing it under Cancelled would misdescribe it.
    AppointmentTab.past =>
      appointments
          .where(
            (a) =>
                a.status == AppointmentStatus.completed ||
                a.status == AppointmentStatus.closed,
          )
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

  /// Rings the doctor.
  ///
  /// Joining is a *call*, not a door: the patient used to be dropped straight
  /// into an empty Agora channel, and the doctor learned a consultation had
  /// started by opening the app and looking at their bookings. Now their phone
  /// rings, and the room opens on both sides when they answer.
  ///
  /// One destination whatever the row says, too. This used to branch on a
  /// `type` chosen at booking time, so the same Join opened a thread on one
  /// appointment and refused outright on another.
  void join(Appointment appointment) =>
      unawaited(Get.find<CallService>().ring(appointment));

  /// Finishes a booking that was left unpaid, at the same Payment Summary
  /// screen booking itself uses.
  void payNow(Appointment appointment) =>
      Get.toNamed<void>(AppRoutes.paymentSummary, arguments: appointment);

  /// True while one of the two lapse remedies is in flight.
  final RxnString resolvingId = RxnString();

  /// Asks the doctor for the fee back on a consultation that never happened.
  ///
  /// Reloads rather than patching in place: the request is the doctor's to
  /// settle, so the card should show what the server now holds rather than
  /// what this device hopes.
  Future<void> requestRefund(Appointment appointment) async {
    if (resolvingId.value != null) return;
    resolvingId.value = appointment.id;
    try {
      await _repository.requestRefund(appointment.id);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    } finally {
      resolvingId.value = null;
    }
    await load();
    AppSnackbar.success(AppStrings.refundRequested.tr);
  }

  /// Opens the doctor's calendar to pick a new time for a lapsed booking.
  ///
  /// Reuses Doctor Details, which is where every other slot is chosen — a
  /// second calendar would be a second set of availability rules to keep in
  /// step with the first.
  void reschedule(Appointment appointment) {
    if (!appointment.needsLapseChoice) {
      bookAppointment();
      return;
    }
    Get.toNamed<void>(
      AppRoutes.doctorDetails,
      arguments: RescheduleRequest(appointment: appointment),
    );
  }

  /// Booking and re-booking both start at the doctor directory.
  void bookAppointment() => Get.find<MainNavController>().select(2);

  void bookAgain(Appointment appointment) => bookAppointment();

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
