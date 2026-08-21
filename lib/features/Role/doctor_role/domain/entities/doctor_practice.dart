/// Shapes behind the practitioner section.
///
/// Served by `DoctorPracticeRepository` — the API implementation reads them
/// off `doctors/me`, `doctors/me/stats`, `appointments`, `wallet` and
/// `lab-orders`; the static implementation keeps the design's sample data for
/// tests and for walking the app without a server.
library;

/// Which tab of the doctor shell is showing.
enum DoctorTab { home, appointments, message, profile }

/// The signed-in practitioner, as the dashboard masthead shows them.
class Practitioner {
  const Practitioner({
    required this.name,
    required this.initials,
    required this.availableBalance,
    this.currency = 'USD',
    this.photoUrl,
    this.hasUnreadNotification = true,
  });

  final String name;

  /// `AH` — drawn in the masthead disc when there is no picture.
  final String initials;

  /// The practitioner's own picture, when the server has one.
  final String? photoUrl;

  final double availableBalance;

  /// ISO code from the wallet. The design was drawn in dollars, so a dollar
  /// wallet keeps its `$`; anything else prints its code rather than wearing
  /// a symbol that belongs to another currency.
  final String currency;

  final bool hasUnreadNotification;

  /// `$160` — whole currency units, as the design prints it.
  String get balanceLabel => money(availableBalance, currency);
}

/// `$160` in dollars, `160 XAF` in anything else.
String money(double amount, String currency) => currency == 'USD'
    ? '\$${amount.toStringAsFixed(0)}'
    : '${amount.toStringAsFixed(0)} $currency';

/// Initials for a monogram disc: `Dr Dana Okafor` → `DO`.
///
/// The honorific is dropped — every practitioner carries one, so keeping it
/// would put `DR` on every disc in the app.
String initialsOf(String name) {
  const honorifics = {'dr', 'dr.', 'mr', 'mr.', 'mrs', 'mrs.', 'ms', 'ms.'};
  final words = name
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty && !honorifics.contains(w.toLowerCase()))
      .toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first[0].toUpperCase();
  return (words.first[0] + words.last[0]).toUpperCase();
}

/// Everything the practitioner dashboard reads in one round trip.
class DoctorDashboard {
  const DoctorDashboard({
    required this.practitioner,
    required this.pendingRequests,
    required this.todaysPatients,
    required this.totalEarned,
    required this.totalPatients,
    required this.load,
    required this.visits,
    required this.consultationFee,
    required this.currency,
  });

  final Practitioner practitioner;

  /// Already formatted, because `$660` is not derivable from a bare number
  /// without knowing the wallet's currency.
  final String pendingRequests;
  final String todaysPatients;
  final String totalEarned;
  final String totalPatients;

  final List<DayLoad> load;
  final List<PatientVisit> visits;

  /// What the practice charges, so Set Fees opens on the current figure
  /// rather than on the design's placeholder.
  final double consultationFee;
  final String currency;

  /// The chart's y-axis top.
  ///
  /// Follows the busiest day, but lands on a readable gridline rather than the
  /// raw peak: a week topping out at 55 gets an axis of 0/15/30/45/60, not
  /// 0/14/28/42/56. Never zero — an empty week would otherwise divide by it.
  int get chartMax {
    final peak = load.fold(0, (max, day) => day.count > max ? day.count : max);
    if (peak <= 0) return chartDivisions;

    for (final step in _gridSteps) {
      if (step * chartDivisions >= peak) return step * chartDivisions;
    }
    // Past the last named step, round up to the nearest whole multiple of it.
    final step = _gridSteps.last;
    final needed = (peak / chartDivisions).ceil();
    return ((needed + step - 1) ~/ step) * step * chartDivisions;
  }

  static const int chartDivisions = 4;

  /// Gaps a reader can add up in their head, smallest first.
  static const List<int> _gridSteps = [1, 2, 5, 10, 15, 20, 25, 50, 100];
}

/// What Earning Withdraw prints above the consultation list.
class DoctorEarnings {
  const DoctorEarnings({
    required this.availableLabel,
    required this.totalEarnedLabel,
    required this.paidOutLabel,
    required this.consultations,
  });

  final String availableLabel;
  final String totalEarnedLabel;
  final String paidOutLabel;
  final List<ConsultationEarning> consultations;
}

/// A destination the doctor can be paid into.
class PayoutAccount {
  const PayoutAccount({
    required this.id,
    required this.label,
    required this.isDefault,
  });

  final String id;

  /// `Mobile money •••• 4321` — what the dialog lists.
  final String label;

  final bool isDefault;
}

/// The practice details behind the doctor's profile and its edit form.
class DoctorProfileDetails {
  const DoctorProfileDetails({
    required this.fullName,
    required this.email,
    required this.specialty,
    required this.experience,
    required this.biography,
    required this.licenceNumber,
    required this.language,
    required this.consultationFee,
    required this.currency,
    this.photoUrl,
  });

  final String fullName;
  final String email;
  final String specialty;

  /// Years, as the form's text field holds it.
  final String experience;

  final String biography;
  final String licenceNumber;
  final String language;
  final double consultationFee;
  final String currency;
  final String? photoUrl;
}

/// One of the four dashboard statistics.
class PracticeStat {
  const PracticeStat({required this.value, required this.label});

  /// Already formatted: `4`, `$660`, `312`.
  final String value;

  final String label;
}

/// A bar on the appointments chart.
class DayLoad {
  const DayLoad({required this.dayLabel, required this.count});

  /// `Mon`.
  final String dayLabel;

  final int count;
}

/// How the chart is grouped.
enum ChartRange { weekly, monthly }

/// Whether the patient's slot is agreed or still waiting on the doctor.
enum VisitStatus { pending, confirmed }

/// A row in the dashboard's Upcoming Appointments card.
class PatientVisit {
  const PatientVisit({
    required this.patientName,
    required this.initials,
    required this.reason,
    required this.timeLabel,
    required this.status,
    this.photoUrl,
  });

  final String patientName;
  final String initials;

  /// Falls back to [initials] when absent or the network image fails to load.
  final String? photoUrl;

  /// `General Consultation`.
  final String reason;

  /// `09:00 AM`.
  final String timeLabel;

  final VisitStatus status;
}

// ─── Appointments ──────────────────────────────────────────────────────────

/// Which chip is active above the doctor's appointment list.
enum DoctorApptFilter { fresh, completed, cancelled }

/// A booking as the practitioner sees it.
class DoctorAppointment {
  const DoctorAppointment({
    required this.id,
    required this.patientName,
    required this.complaint,
    required this.scheduledAt,
    required this.filter,
    this.isJoinable = false,
    this.photoAsset,
    this.photoUrl,
    this.initials,
    this.age,
    this.summary,
    this.fee,
    this.isClosed = false,
    this.isRefunded = false,
    this.isRefundRequested = false,
    this.isRescheduled = false,
  });

  final String id;
  final String patientName;

  /// `Sleeping Patients` — what the patient came about.
  final String complaint;

  final DateTime scheduledAt;
  final DoctorApptFilter filter;

  /// `SM`, on the completed card's tinted disc.
  final String? initials;

  final int? age;

  /// `Persistent headache and fatigue` — the second line of a completed card.
  final String? summary;

  /// What the consultation earned.
  final double? fee;

  /// The slot passed with neither side acting. Grouped with completed work —
  /// it is over either way — but it did not happen, and the fee is still the
  /// patient's until the doctor sends it back.
  final bool isClosed;

  final bool isRefunded;

  /// The patient asked for their money back, rather than taking a new slot.
  final bool isRefundRequested;

  /// The patient took a new slot instead, so the fee carried across and there
  /// is nothing left to refund.
  final bool isRescheduled;

  /// Only a lapsed consultation that has not already been settled either way.
  bool get canRefund => isClosed && !isRefunded && !isRescheduled;

  /// `General Consultation • Age 34`.
  String get complaintLine => age == null ? complaint : '$complaint • Age $age';

  /// `07/14` — the completed card prints the day, not the year.
  String get shortDateLabel =>
      '${scheduledAt.month.toString().padLeft(2, '0')}/'
      '${scheduledAt.day.toString().padLeft(2, '0')}';

  /// `09:00 AM`.
  String get timeLabel {
    final hour12 = scheduledAt.hour % 12 == 0 ? 12 : scheduledAt.hour % 12;
    final minute = scheduledAt.minute.toString().padLeft(2, '0');
    return '${hour12.toString().padLeft(2, '0')}:$minute '
        '${scheduledAt.hour < 12 ? 'AM' : 'PM'}';
  }

  String get feeLabel => fee == null ? '' : '\$${fee!.toStringAsFixed(0)}';

  /// True only for the visit whose room is open; the rest show a muted Join.
  final bool isJoinable;

  /// Bundled placeholder, used by the static data the goldens render.
  final String? photoAsset;

  /// The patient's own photo, when the server has one.
  final String? photoUrl;

  /// `Apr 2, 2026 at 11:00 AM`, hand-formatted like every other date label.
  String get scheduleLabel {
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
    final hour12 = scheduledAt.hour % 12 == 0 ? 12 : scheduledAt.hour % 12;
    final minute = scheduledAt.minute.toString().padLeft(2, '0');
    final period = scheduledAt.hour < 12 ? 'AM' : 'PM';
    return '${months[scheduledAt.month - 1]} ${scheduledAt.day}, '
        '${scheduledAt.year} at $hour12:$minute $period';
  }
}

// ─── Prescribing ───────────────────────────────────────────────────────────

/// A line the doctor is writing onto a prescription.
/// The unit a strength is measured in.
enum DoseUnit { mg, mcg, g, ml, iu, tablet, capsule, drop, puff }

extension DoseUnitLabel on DoseUnit {
  /// What goes after the number: `500 mg`, `2 tablet`.
  String get label => switch (this) {
    DoseUnit.mg => 'mg',
    DoseUnit.mcg => 'mcg',
    DoseUnit.g => 'g',
    DoseUnit.ml => 'ml',
    DoseUnit.iu => 'IU',
    DoseUnit.tablet => 'tablet',
    DoseUnit.capsule => 'capsule',
    DoseUnit.drop => 'drop',
    DoseUnit.puff => 'puff',
  };
}

/// When the dose is taken relative to eating.
///
/// A choice rather than free text: "after meals", "Aftermeals" and "p.c." all
/// mean the same thing, and a pharmacist reading the script should not have to
/// work out which one a doctor typed.
enum MealTiming { anytime, beforeMeal, afterMeal, withFood }

class PrescribedMedicine {
  const PrescribedMedicine({
    required this.name,
    required this.strength,
    required this.unit,
    required this.durationDays,
    required this.timesPerDay,
    required this.timing,
    this.notes = '',
  });

  /// The drug alone — `Amoxicillin`, not `Amoxicillin 500mg`. The strength is
  /// its own field so a pharmacy can read it without parsing a name.
  final String name;

  /// How much per dose, as typed: `500`.
  final String strength;

  final DoseUnit unit;

  final int durationDays;

  /// Doses in a day.
  final int timesPerDay;

  final MealTiming timing;

  /// Anything the two structured fields cannot say.
  final String notes;

  String get durationLabel => '$durationDays days';

  /// `500 mg`.
  String get doseLabel => '$strength ${unit.label}';
}

/// `3 times daily, after meal` — what the server stores as one `frequency`.
///
/// The app keeps the count and the meal timing apart so the form can ask for
/// them separately, and joins them here because the API has a single field.
String prescriptionFrequency(PrescribedMedicine medicine) {
  final times = '${medicine.timesPerDay} times daily';
  return switch (medicine.timing) {
    MealTiming.anytime => times,
    MealTiming.beforeMeal => '$times, before meal',
    MealTiming.afterMeal => '$times, after meal',
    MealTiming.withFood => '$times, with food',
  };
}

// ─── Earnings ──────────────────────────────────────────────────────────────

/// Whether a consultation's fee has been paid out yet.
enum PayoutState { pending, completed }

/// One row of Recent Consultations on Earning Withdraw.
class ConsultationEarning {
  const ConsultationEarning({
    required this.id,
    required this.patientName,
    required this.earnedOn,
    required this.amountLabel,
    required this.state,
  });

  final String id;
  final String patientName;
  final DateTime earnedOn;

  /// `+5,000 XAF` — already formatted, because the currency is the doctor's
  /// and not derivable from a bare number.
  final String amountLabel;

  final PayoutState state;
}

// ─── Messaging ─────────────────────────────────────────────────────────────

/// A row in the doctor's Message list.
class PatientThread {
  const PatientThread({
    required this.id,
    required this.patientName,
    required this.preview,
    required this.timeLabel,
    required this.unreadCount,
    this.patientUserId = '',
    this.photoAsset,
    this.photoUrl,
  });

  /// The consultation this thread belongs to. Threads are keyed by
  /// appointment on the server, so this is also the room to join.
  final String id;

  /// The patient's own user id, which is *not* [id].
  ///
  /// Presence is published per user, so the two must not be confused: the
  /// doctor's thread used to pass the appointment id as the peer's id, and
  /// every presence lookup then asked about a user that does not exist and
  /// came back offline. Empty only when the appointment behind the thread
  /// could not be read.
  final String patientUserId;

  final String patientName;

  /// The last message, truncated by the row.
  final String preview;

  /// `18:31`.
  final String timeLabel;

  final int unreadCount;

  /// Bundled placeholder, used by the static data the goldens render.
  final String? photoAsset;

  /// The patient's own photo, when the server has one.
  final String? photoUrl;
}

// ─── Schedule ──────────────────────────────────────────────────────────────

/// One bookable slot on a working day.
///
/// Carries minutes past midnight as well as its label: the label is what the
/// chip prints, but `PUT /doctors/me/availability` wants a window, and reading
/// one back out of `02-03 PM` would mean re-parsing text the app already had
/// in numeric form.
class TimeSlot {
  const TimeSlot({
    required this.label,
    required this.startMinute,
    required this.endMinute,
  });

  /// Builds the label from the window: `840, 900` → `02-03 PM`.
  factory TimeSlot.fromMinutes(int startMinute, int endMinute) => TimeSlot(
    label: _slotLabel(startMinute, endMinute),
    startMinute: startMinute,
    endMinute: endMinute,
  );

  /// `02-03 PM`.
  final String label;

  /// Minutes past midnight, `0..1440`.
  final int startMinute;
  final int endMinute;

  /// `02-03 PM` for a whole hour, `12:00-12:30 AM` when either end is not on
  /// one.
  ///
  /// Printing only the hour is what the design shows, and it reads correctly
  /// for the hour-long slots it was drawn with. A practice on 30-minute slots
  /// gets "12-12 AM" for 00:00–00:30 and "12-01 AM" for 00:30–01:00 — two
  /// different half-hours that look like the same hour, and neither says which
  /// half. So minutes appear as soon as they matter.
  static String _slotLabel(int start, int end) {
    String hh(int minutes) {
      final hour = (minutes ~/ 60) % 24;
      final hour12 = hour % 12 == 0 ? 12 : hour % 12;
      return hour12.toString().padLeft(2, '0');
    }

    String hhmm(int minutes) =>
        '${hh(minutes)}:${(minutes % 60).toString().padLeft(2, '0')}';

    final period = (end ~/ 60) % 24 < 12 ? 'AM' : 'PM';
    final onTheHour = start % 60 == 0 && end % 60 == 0;

    return onTheHour
        ? '${hh(start)}-${hh(end)} $period'
        : '${hhmm(start)}-${hhmm(end)} $period';
  }
}

/// A weekday in the schedule editor.
class ScheduleDay {
  const ScheduleDay({
    required this.name,
    required this.dayOfMonth,
    required this.isOpen,
    required this.slots,
    this.dayOfWeek = 0,
  });

  /// `Monday`.
  final String name;

  /// `12` — shown in the day circle.
  final int dayOfMonth;

  /// Sunday is 0, matching the availability documents the server stores.
  final int dayOfWeek;

  /// Whether the day's toggle is on.
  final bool isOpen;

  final List<TimeSlot> slots;

  ScheduleDay copyWith({bool? isOpen, List<TimeSlot>? slots}) => ScheduleDay(
    name: name,
    dayOfMonth: dayOfMonth,
    dayOfWeek: dayOfWeek,
    isOpen: isOpen ?? this.isOpen,
    slots: slots ?? this.slots,
  );
}
