/// Shapes behind the practitioner section.
///
/// **Names only, by design.** This feature is UI-first: no repository, use
/// case or data source sits under it and nothing calls an API — the same
/// arrangement as `pharmacy`, `profile` and `medical_vault`.
library;

/// Which tab of the doctor shell is showing.
enum DoctorTab { home, appointments, message, profile }

/// The signed-in practitioner, as the dashboard masthead shows them.
class Practitioner {
  const Practitioner({
    required this.name,
    required this.initials,
    required this.availableBalance,
    this.hasUnreadNotification = true,
  });

  final String name;

  /// `AH` — drawn in the masthead disc.
  final String initials;

  final double availableBalance;
  final bool hasUnreadNotification;

  /// `$160` — whole currency units, as the design prints it.
  String get balanceLabel => '\$${availableBalance.toStringAsFixed(0)}';
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
  });

  final String patientName;
  final String initials;

  /// `General Consultation`.
  final String reason;

  /// `09:00 AM`.
  final String timeLabel;

  final VisitStatus status;
}

// ─── Schedule ──────────────────────────────────────────────────────────────

/// One bookable slot on a working day.
class TimeSlot {
  const TimeSlot({required this.label});

  /// `02-03 PM`.
  final String label;
}

/// A weekday in the schedule editor.
class ScheduleDay {
  const ScheduleDay({
    required this.name,
    required this.dayOfMonth,
    required this.isOpen,
    required this.slots,
  });

  /// `Monday`.
  final String name;

  /// `12` — shown in the day circle.
  final int dayOfMonth;

  /// Whether the day's toggle is on.
  final bool isOpen;

  final List<TimeSlot> slots;

  ScheduleDay copyWith({bool? isOpen, List<TimeSlot>? slots}) => ScheduleDay(
    name: name,
    dayOfMonth: dayOfMonth,
    isOpen: isOpen ?? this.isOpen,
    slots: slots ?? this.slots,
  );
}
