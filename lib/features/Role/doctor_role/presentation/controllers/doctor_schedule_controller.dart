import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../data/static/doctor_practice_data.dart';
import '../../domain/entities/doctor_practice.dart';
import '../../domain/repositories/doctor_practice_repository.dart';

/// Backs Set Schedule: the year/month/week pickers, the day strip, and one
/// card per day with its slots.
///
/// The server holds a weekly pattern rather than dated days, so the pickers
/// choose which week the pattern is laid over — changing them re-reads it,
/// and saving writes the pattern back for every weekday the editor shows.
class DoctorScheduleController extends GetxController {
  DoctorScheduleController({DoctorPracticeRepository? repository})
    : _repository = repository ?? Get.find<DoctorPracticeRepository>();

  final DoctorPracticeRepository _repository;

  final RxString year = DoctorPracticeData.years.first.obs;
  final RxString month = DoctorPracticeData.months[6].obs;
  final RxString week = DoctorPracticeData.weeks[1].obs;

  final RxList<ScheduleDay> days = <ScheduleDay>[].obs;

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxnString error = RxnString();

  /// Start and end of the slot being added, per day index. Held as plain
  /// strings so the inputs own their text controllers.
  final RxMap<int, String> starts = <int, String>{}.obs;
  final RxMap<int, String> ends = <int, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      days.value = await _repository.availability(_anchor);
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  /// A date inside the week the pickers name, which is what the repository
  /// lays the weekly pattern over. Falls back to today when the three
  /// selections do not describe a real date.
  DateTime get _anchor {
    final y = int.tryParse(year.value);
    final m = DoctorPracticeData.months.indexOf(month.value) + 1;
    final firstDay = int.tryParse(week.value.split('-').first);
    if (y == null || m == 0 || firstDay == null) return DateTime.now();
    return DateTime(y, m, firstDay);
  }

  // ─── Pickers ─────────────────────────────────────────────────────────────

  void selectYear(String value) {
    year.value = value;
    load();
  }

  void selectMonth(String value) {
    month.value = value;
    load();
  }

  void selectWeek(String value) {
    week.value = value;
    load();
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

  /// Adds `start-end` as a slot. Both halves are required and both have to be
  /// readable as a time — the server stores minutes, so a chip whose text
  /// cannot be turned into one would be dropped silently on the next save.
  void addSlot(int index) {
    final start = minutesOf(startOf(index));
    final end = minutesOf(endOf(index));
    if (start == null || end == null || end <= start) {
      AppSnackbar.info(AppStrings.slotNeedsBothTimes.tr);
      return;
    }
    final day = days[index];
    days[index] = day.copyWith(
      slots: [...day.slots, TimeSlot.fromMinutes(start, end)],
    );
  }

  /// `14:30`, `2:30 PM`, `2 PM` and a bare `14` all read as minutes past
  /// midnight; anything else is refused.
  static int? minutesOf(String raw) {
    final text = raw.trim().toUpperCase();
    if (text.isEmpty) return null;

    final match = RegExp(r'^(\d{1,2})(?::(\d{2}))?\s*(AM|PM)?$').firstMatch(
      text,
    );
    if (match == null) return null;

    var hour = int.parse(match.group(1)!);
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    final period = match.group(3);

    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    if (hour > 23 || minute > 59) return null;

    return hour * 60 + minute;
  }

  void removeSlot(int dayIndex, int slotIndex) {
    final day = days[dayIndex];
    days[dayIndex] = day.copyWith(slots: [...day.slots]..removeAt(slotIndex));
  }

  // ─── Summary ─────────────────────────────────────────────────────────────

  int get activeDays => days.where((day) => day.isOpen).length;

  /// The hours actually on the calendar, rather than a fixed day length —
  /// a doctor who opens two slots has not worked eight hours.
  int get totalHours {
    final minutes = days
        .where((day) => day.isOpen)
        .expand((day) => day.slots)
        .fold(0, (sum, slot) => sum + (slot.endMinute - slot.startMinute));
    return minutes ~/ 60;
  }

  /// One patient per slot, which is what a slot is.
  int get maxPatients =>
      days.where((day) => day.isOpen).fold(0, (n, day) => n + day.slots.length);

  String get totalHoursLabel => '${totalHours}h';

  Future<void> save() async {
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      await _repository.saveAvailability(days.toList());
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    } finally {
      isSaving.value = false;
    }
    AppSnackbar.success(AppStrings.scheduleSaved.tr);
    Get.back<void>();
  }
}
