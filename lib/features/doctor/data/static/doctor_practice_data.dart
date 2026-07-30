import '../../domain/entities/doctor_practice.dart';

/// Sample practice data behind the doctor dashboard and schedule editor.
///
/// Static by design — this feature is UI-first, so there is no repository or
/// API here; the shapes are what a future endpoint will fill in.
class DoctorPracticeData {
  DoctorPracticeData._();

  static const Practitioner practitioner = Practitioner(
    name: 'Dr. Aisha Hassan',
    initials: 'AH',
    availableBalance: 160,
  );

  static const String pendingRequests = '4';
  static const String todaysPatients = '1';
  static const String totalEarned = r'$660';
  static const String totalPatients = '312';

  /// Monday through Sunday, matching the chart's bar heights.
  static const List<DayLoad> weeklyLoad = [
    DayLoad(dayLabel: 'Mon', count: 45),
    DayLoad(dayLabel: 'Tue', count: 18),
    DayLoad(dayLabel: 'Wed', count: 55),
    DayLoad(dayLabel: 'Thu', count: 48),
    DayLoad(dayLabel: 'Fri', count: 35),
    DayLoad(dayLabel: 'Sat', count: 28),
    DayLoad(dayLabel: 'Sun', count: 22),
  ];

  /// The chart's y-axis tops out here, which is what puts the gridlines at
  /// 0 / 15 / 30 / 45 / 60.
  static const int chartMax = 60;
  static const int chartDivisions = 4;

  static const List<PatientVisit> upcomingVisits = [
    PatientVisit(
      patientName: 'Sarah Mitchell',
      initials: 'SM',
      reason: 'General Consultation',
      timeLabel: '09:00 AM',
      status: VisitStatus.pending,
    ),
    PatientVisit(
      patientName: 'James Okafor',
      initials: 'JO',
      reason: 'Follow-up',
      timeLabel: '10:30 AM',
      status: VisitStatus.confirmed,
    ),
    PatientVisit(
      patientName: 'Emily Chen',
      initials: 'EC',
      reason: 'Cardiology Review',
      timeLabel: '12:00 PM',
      status: VisitStatus.pending,
    ),
    PatientVisit(
      patientName: 'Robert Kline',
      initials: 'RK',
      reason: 'Diabetes Management',
      timeLabel: '09:30 AM',
      status: VisitStatus.confirmed,
    ),
  ];

  // ─── Schedule ────────────────────────────────────────────────────────────

  static const List<String> years = ['2026', '2027'];

  static const List<String> months = [
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

  static const List<String> weeks = ['5-11', '12-18', '19-25', '26-31'];

  /// The six slots every open day starts with in the design.
  static const List<TimeSlot> defaultSlots = [
    TimeSlot(label: '02-03 PM'),
    TimeSlot(label: '03-04 PM'),
    TimeSlot(label: '04-05 PM'),
    TimeSlot(label: '09-10 AM'),
    TimeSlot(label: '10-11 AM'),
    TimeSlot(label: '12-01 PM'),
  ];

  /// Monday to Sunday for the `12-18` week, with the weekend closed — which
  /// is why F 16 and S 17 are unfilled circles in the design.
  static List<ScheduleDay> week() => [
    ScheduleDay(
      name: 'Monday',
      dayOfMonth: 12,
      isOpen: true,
      slots: List.of(defaultSlots),
    ),
    ScheduleDay(
      name: 'Tuesday',
      dayOfMonth: 13,
      isOpen: true,
      slots: List.of(defaultSlots),
    ),
    ScheduleDay(
      name: 'Wednesday',
      dayOfMonth: 14,
      isOpen: true,
      slots: List.of(defaultSlots),
    ),
    ScheduleDay(
      name: 'Thursday',
      dayOfMonth: 15,
      isOpen: true,
      slots: List.of(defaultSlots),
    ),
    const ScheduleDay(name: 'Friday', dayOfMonth: 16, isOpen: false, slots: []),
    const ScheduleDay(
      name: 'Saturday',
      dayOfMonth: 17,
      isOpen: false,
      slots: [],
    ),
    ScheduleDay(
      name: 'Sunday',
      dayOfMonth: 18,
      isOpen: true,
      slots: List.of(defaultSlots),
    ),
  ];

  static const int maxPatients = 46;

  /// Hours per open day, used for the weekly total.
  static const int hoursPerDay = 8;

  // ─── Fees ────────────────────────────────────────────────────────────────

  static const List<String> currencies = ['CAD', 'USD', 'XAF', 'EUR'];

  static const String defaultFeeHint = r'$440';
}
