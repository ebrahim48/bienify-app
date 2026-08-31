import 'doctor.dart';

/// The full profile behind a [Doctor], loaded when the details screen opens.
class DoctorDetails {
  const DoctorDetails({
    required this.doctor,
    required this.experienceYears,
    required this.workingTime,
    required this.languages,
    required this.biography,
    this.heroImage,
  });

  final Doctor doctor;

  final int experienceYears;

  /// Patients treated, formatted for the stat tile — the design shows `2.7k+`.
  ///
  /// Derived from [Doctor.patientsSeen] rather than carried as its own field.
  /// It used to be a `String` on this constructor, and the API repository
  /// passed the literal `'—'` with a comment saying the server did not count a
  /// doctor's patients. The server does: `GET /doctors/:id` has been answering
  /// with `patientsSeen` — distinct patients from completed appointments — and
  /// the mapper has been reading it into the doctor all along. The tile said
  /// "—" over the caption "Patients" on every profile regardless. Deriving it
  /// here means there is no field left to hard-code.
  String get patientCount {
    final seen = doctor.patientsSeen;
    if (seen < 1000) return '$seen';
    // `2.7k+` rather than `2,700`: the tile is narrow, and the trailing plus is
    // honest about the rounding rather than implying an exact figure.
    final thousands = (seen / 1000).toStringAsFixed(1);
    return '${thousands.endsWith('.0') ? thousands.substring(0, thousands.length - 2) : thousands}k+';
  }

  /// e.g. `Sun-Sat, 9AM - 5PM`.
  final String workingTime;

  final List<String> languages;
  final String biography;

  /// Full-bleed portrait shown at the top of the screen.
  final String? heroImage;

  String get languagesLabel => languages.join(', ');
}

/// A bookable slot on a given day.
class TimeSlot {
  const TimeSlot({required this.label, this.startsAt, this.isBooked = false});

  /// e.g. `10:30 AM`.
  final String label;

  /// The instant the server offered, kept alongside the label it is shown as.
  ///
  /// Booking is refused unless `slotStart` equals one of the server's own slot
  /// starts exactly, so the value has to survive the round trip rather than be
  /// rebuilt from `10:30 AM` — a label cannot carry the date, and parsing one
  /// back guesses at both the day and the timezone.
  ///
  /// Null for the sample data, which has no real instant behind it.
  final DateTime? startsAt;

  /// Booked slots are shown struck through and cannot be selected.
  final bool isBooked;
}

/// One selectable day in the availability strip.
class AvailableDay {
  const AvailableDay({required this.date, required this.slots});

  final DateTime date;
  final List<TimeSlot> slots;

  /// `5` — the day number shown in the chip.
  String get dayLabel => '${date.day}';

  /// `Wed` — the weekday abbreviation under it.
  String get weekdayLabel => switch (date.weekday) {
    DateTime.monday => 'Mon',
    DateTime.tuesday => 'Tue',
    DateTime.wednesday => 'Wed',
    DateTime.thursday => 'Thu',
    DateTime.friday => 'Fri',
    DateTime.saturday => 'Sat',
    _ => 'Sun',
  };
}

/// Everything the date/time picker on the details screen needs.
class DoctorAvailability {
  const DoctorAvailability({
    required this.year,
    required this.months,
    required this.selectedMonth,
    required this.days,
  });

  final int year;

  /// Month names offered by the horizontal strip.
  final List<String> months;

  final String selectedMonth;
  final List<AvailableDay> days;
}
