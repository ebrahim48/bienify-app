import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../chat/domain/entities/conversation.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/entities/doctor_details.dart';
import '../../domain/usecases/doctor_usecases.dart';

/// Backs the Doctor Details screen, including the date and time pickers.
class DoctorDetailsController extends GetxController with SubmissionMixin {
  DoctorDetailsController({
    required this.doctor,
    required GetDoctorDetails getDetails,
    required GetDoctorAvailability getAvailability,
  }) : _getDetails = getDetails,
       _getAvailability = getAvailability;

  final Doctor doctor;
  final GetDoctorDetails _getDetails;
  final GetDoctorAvailability _getAvailability;

  final Rxn<DoctorDetails> details = Rxn<DoctorDetails>();
  final Rxn<DoctorAvailability> availability = Rxn<DoctorAvailability>();

  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  final RxnString selectedMonth = RxnString();
  final Rxn<AvailableDay> selectedDay = Rxn<AvailableDay>();
  final Rxn<TimeSlot> selectedSlot = Rxn<TimeSlot>();

  /// A booking needs both a day and a free slot.
  bool get canBook => selectedDay.value != null && selectedSlot.value != null;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      details.value = await _getDetails(doctor.id);
      final slots = await _getAvailability(doctor.id);
      availability.value = slots;
      selectedMonth.value = slots.selectedMonth;
      // Pre-select the day the design highlights: the middle of the strip.
      if (slots.days.isNotEmpty) {
        selectDay(slots.days[slots.days.length ~/ 2]);
      }
    } on AppException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = AppStrings.somethingWentWrong.tr;
    } finally {
      isLoading.value = false;
    }
  }

  void selectMonth(String month) => selectedMonth.value = month;

  void selectDay(AvailableDay day) {
    selectedDay.value = day;
    // A slot from the previous day may not exist on this one.
    selectedSlot.value = null;
  }

  /// Booked slots are display-only, so taps on them are ignored.
  void selectSlot(TimeSlot slot) {
    if (slot.isBooked) return;
    selectedSlot.value = slot;
  }

  /// Opens the chat thread with this doctor.
  void openChat() => Get.toNamed<void>(
    AppRoutes.chat,
    arguments: ConversationPeer(
      id: doctor.id,
      name: doctor.name,
      specialty: doctor.specialty,
      isOnline: true,
    ),
  );

  /// Carries the chosen slot into the payment summary.
  void bookAppointment() {
    if (!canBook) {
      AppSnackbar.info(AppStrings.selectTimeSlot.tr);
      return;
    }

    final day = selectedDay.value!;
    final slot = selectedSlot.value!;

    Get.toNamed<void>(
      AppRoutes.paymentSummary,
      arguments: Appointment(
        id: 'draft-${doctor.id}-${day.date.millisecondsSinceEpoch}',
        doctorName: doctor.name,
        specialty: doctor.specialty,
        scheduledAt: _combine(day.date, slot.label),
      ),
    );
  }

  /// Merges a selected day with a slot label such as `02:30 AM`.
  DateTime _combine(DateTime day, String label) {
    final match = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)').firstMatch(label);
    if (match == null) return day;

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final isPm = match.group(3) == 'PM';
    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;

    return DateTime(day.year, day.month, day.day, hour, minute);
  }
}
