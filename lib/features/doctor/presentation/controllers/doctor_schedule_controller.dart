import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/static/doctor_practice_data.dart';
import '../../domain/entities/doctor_practice.dart';

/// Backs Set Schedule: the year/month/week pickers, the day strip, and one
/// card per day with its slots.
///
/// UI-only — the week comes from [DoctorPracticeData] and nothing is saved
/// anywhere.
class DoctorScheduleController extends GetxController {
  final RxString year = DoctorPracticeData.years.first.obs;
  final RxString month = DoctorPracticeData.months[6].obs;
  final RxString week = DoctorPracticeData.weeks[1].obs;

  final RxList<ScheduleDay> days = <ScheduleDay>[].obs;

  /// Start and end of the slot being added, per day index. Held as plain
  /// strings so the inputs own their text controllers.
  final RxMap<int, String> starts = <int, String>{}.obs;
  final RxMap<int, String> ends = <int, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    days.value = DoctorPracticeData.week();
  }

  // ─── Pickers ─────────────────────────────────────────────────────────────

  void selectYear(String value) => year.value = value;

  void selectMonth(String value) => month.value = value;

  /// Changing the week resets the days, which is what a real fetch would do.
  void selectWeek(String value) {
    week.value = value;
    days.value = DoctorPracticeData.week();
  }

  // ─── Days ────────────────────────────────────────────────────────────────

  void toggleDay(int index, bool isOpen) {
    final day = days[index];
    days[index] = day.copyWith(
      isOpen: isOpen,
      // Closing a day clears its slots; re-opening restores the defaults,
      // because a day with no hours cannot be booked.
      slots: isOpen
          ? (day.slots.isEmpty
                ? List.of(DoctorPracticeData.defaultSlots)
                : day.slots)
          : const [],
    );
  }

  void setStart(int index, String value) => starts[index] = value;

  void setEnd(int index, String value) => ends[index] = value;

  String startOf(int index) => starts[index] ?? '';

  String endOf(int index) => ends[index] ?? '';

  /// Adds `start-end` as a slot. Both halves are required, so an empty pair
  /// says so rather than silently adding a blank chip.
  void addSlot(int index) {
    final start = startOf(index).trim();
    final end = endOf(index).trim();
    if (start.isEmpty || end.isEmpty) {
      AppSnackbar.info(AppStrings.slotNeedsBothTimes.tr);
      return;
    }
    final day = days[index];
    days[index] = day.copyWith(
      slots: [
        ...day.slots,
        TimeSlot(label: '$start-$end'),
      ],
    );
  }

  void removeSlot(int dayIndex, int slotIndex) {
    final day = days[dayIndex];
    days[dayIndex] = day.copyWith(slots: [...day.slots]..removeAt(slotIndex));
  }

  // ─── Summary ─────────────────────────────────────────────────────────────

  int get activeDays => days.where((day) => day.isOpen).length;

  int get totalHours => activeDays * DoctorPracticeData.hoursPerDay;

  int get maxPatients => DoctorPracticeData.maxPatients;

  String get totalHoursLabel => '${totalHours}h';

  void save() {
    AppSnackbar.success(AppStrings.scheduleSaved.tr);
    Get.back<void>();
  }
}
