import '../../../../../core/constants/app_assets.dart';
import '../../../patient/medical_vault/domain/entities/medical_record.dart';
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

  // ─── Appointments ────────────────────────────────────────────────────────

  /// Two on the New tab — one whose room is open and one not yet — plus a row
  /// under each of the other chips, so every state is reachable.
  static List<DoctorAppointment> appointments() => [
    DoctorAppointment(
      id: 'appt-1',
      patientName: 'Mr. John Smith',
      complaint: 'Sleeping Patients',
      scheduledAt: DateTime(2026, 4, 2, 11),
      filter: DoctorApptFilter.fresh,
      photoAsset: AppAssets.doctorPlaceholder,
    ),
    DoctorAppointment(
      id: 'appt-2',
      patientName: 'Mr. John Smith',
      complaint: 'Sleeping Patients',
      scheduledAt: DateTime(2026, 4, 2, 11),
      filter: DoctorApptFilter.fresh,
      isJoinable: true,
      photoAsset: AppAssets.doctorPlaceholder,
    ),
    // The completed rows carry the extra detail the design prints on them:
    // an initials disc, the patient's age, the complaint, and the fee.
    for (var index = 0; index < 4; index++)
      DoctorAppointment(
        id: 'appt-done-$index',
        patientName: 'Sarah Mitchell',
        initials: 'SM',
        age: 34,
        complaint: 'General Consultation',
        summary: 'Persistent headache and fatigue',
        scheduledAt: DateTime(2026, 7, 14, 9),
        fee: 120,
        filter: DoctorApptFilter.completed,
      ),
    DoctorAppointment(
      id: 'appt-4',
      patientName: 'Mr. James Okafor',
      complaint: 'Follow-up',
      scheduledAt: DateTime(2026, 3, 21, 14),
      filter: DoctorApptFilter.cancelled,
      photoAsset: AppAssets.doctorPlaceholder,
    ),
  ];

  /// What the patient attached to the booking.
  static List<UploadedDocument> patientDocuments() => [
    UploadedDocument(
      id: 'doc-1',
      fileName: 'image (7).png',
      kindLabel: 'Lab Result',
      uploadedOn: DateTime(2026, 4, 3),
    ),
    UploadedDocument(
      id: 'doc-2',
      fileName: 'image (7).png',
      kindLabel: 'Doctor Presecripiton',
      uploadedOn: DateTime(2026, 4, 3),
    ),
  ];

  // ─── Earnings ────────────────────────────────────────────────────────────

  static const String availableBalanceLabel = '10,000 XAF';
  static const String totalEarnedLabel = '15,000 XAF';
  static const String paidOutLabel = '0 XAF';

  static List<ConsultationEarning> earnings() => [
    ConsultationEarning(
      id: 'earn-1',
      patientName: 'John Doe',
      earnedOn: DateTime(2026, 4, 3),
      amountLabel: '+5,000 XAF',
      state: PayoutState.pending,
    ),
    ConsultationEarning(
      id: 'earn-2',
      patientName: 'John Doe',
      earnedOn: DateTime(2026, 4, 3),
      amountLabel: '+5,000 XAF',
      state: PayoutState.pending,
    ),
    ConsultationEarning(
      id: 'earn-3',
      patientName: 'John Doe',
      earnedOn: DateTime(2026, 4, 3),
      amountLabel: '+5,000 XAF',
      state: PayoutState.completed,
    ),
  ];

  // ─── Profile ─────────────────────────────────────────────────────────────

  static const List<String> specialties = [
    'General Practice',
    'Cardiology',
    'Pediatrics',
    'Dermatology',
  ];

  static const List<String> countries = [
    '🇨🇲  Cameroon',
    '🇬🇭  Ghana',
    '🇳🇬  Nigeria',
    '🇺🇸  United States',
  ];

  static const List<String> languages = [
    '🇬🇧  English',
    '🇪🇸  Spanish',
    '🇫🇷  French',
  ];

  // ─── Prescribing ─────────────────────────────────────────────────────────

  /// The two lines already on the script when Write Prescriptions opens.
  static List<PrescribedMedicine> prescribed() => [
    const PrescribedMedicine(
      name: 'Amoxicillin 500mg',
      durationDays: 7,
      dailyDose: 3,
      instructions: 'Take with food',
    ),
    const PrescribedMedicine(
      name: 'Ibuprofen 400mg',
      durationDays: 5,
      dailyDose: 3,
      instructions: 'Take with food or milk',
    ),
  ];

  /// Dosage and frequency wording the design prints on those two cards. A
  /// written line cannot reproduce it from a dose count alone, so the seeded
  /// pair keep their own copy.
  static const Map<String, (String, String)> seededDosage = {
    'Amoxicillin 500mg': ('1 capsule', '3 times daily'),
    'Ibuprofen 400mg': ('1 tablet', 'As needed (max 3 times daily)'),
  };

  // ─── Messaging ───────────────────────────────────────────────────────────

  /// Photos rather than monograms, as every other people list in the app.
  static const List<PatientThread> threads = [
    PatientThread(
      id: 'thread-1',
      patientName: 'Darlene Steward',
      preview: 'Pls take a look at the images....',
      timeLabel: '18:31',
      unreadCount: 5,
      photoAsset: AppAssets.doctorPlaceholder,
    ),
    PatientThread(
      id: 'thread-2',
      patientName: 'Darlene Steward',
      preview: 'Pls take a look at the images....',
      timeLabel: '18:31',
      unreadCount: 5,
      photoAsset: AppAssets.doctorPlaceholder,
    ),
    PatientThread(
      id: 'thread-3',
      patientName: 'Marcus Lee',
      preview: 'The new design is fantastic!',
      timeLabel: '14:05',
      unreadCount: 3,
      photoAsset: AppAssets.doctorPlaceholder,
    ),
    PatientThread(
      id: 'thread-4',
      patientName: 'Sophie Chen',
      preview: 'Can we discuss the color scheme?',
      timeLabel: '09:47',
      unreadCount: 4,
      photoAsset: AppAssets.doctorPlaceholder,
    ),
    PatientThread(
      id: 'thread-5',
      patientName: 'James Johnson',
      preview: 'I have some feedback on the layout.',
      timeLabel: '11:22',
      unreadCount: 2,
      photoAsset: AppAssets.doctorPlaceholder,
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
