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
    this.initials,
    this.age,
    this.summary,
    this.fee,
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

  final String? photoAsset;

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
class PrescribedMedicine {
  const PrescribedMedicine({
    required this.name,
    required this.durationDays,
    required this.dailyDose,
    required this.instructions,
  });

  final String name;
  final int durationDays;
  final int dailyDose;
  final String instructions;

  String get durationLabel => '$durationDays days';

  /// `1 capsule` is not knowable from a dose count, so the card prints the
  /// count itself — which is what the design shows once a line is added.
  String get doseLabel => '$dailyDose';
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
    this.photoAsset,
  });

  final String id;
  final String patientName;

  /// The last message, truncated by the row.
  final String preview;

  /// `18:31`.
  final String timeLabel;

  final int unreadCount;
  final String? photoAsset;
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
