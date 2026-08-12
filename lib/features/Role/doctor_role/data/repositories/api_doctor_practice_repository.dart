import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/mappers.dart';
import '../../../patient/medical_vault/domain/entities/medical_record.dart';
import '../../domain/entities/doctor_practice.dart';
import '../../domain/entities/test_request.dart';
import '../../domain/repositories/doctor_practice_repository.dart';

/// The practitioner's practice, served by the API.
class ApiDoctorPracticeRepository implements DoctorPracticeRepository {
  const ApiDoctorPracticeRepository(this._api);

  final ApiClient _api;

  /// The server caps a page at 100, and the doctor's list has no paging in the
  /// design — so the oldest bookings fall off rather than the screen showing a
  /// partial list it presents as complete.
  static const int _pageSize = 100;

  /// `GET /appointments` filters by the caller's *patient* id unless told
  /// otherwise, so a doctor asking without this gets an empty list rather than
  /// an error — the failure the app hit before this was passed.
  static const Map<String, dynamic> _asDoctor = {
    'role': 'doctor',
    'limit': _pageSize,
  };

  // ─── Dashboard ───────────────────────────────────────────────────────────

  @override
  Future<DoctorDashboard> dashboard() async {
    // Four independent reads; run together so the dashboard costs one round
    // trip's latency rather than four.
    final results = await Future.wait([
      _api.getMap(ApiConstants.usersMe),
      _api.getMap(ApiConstants.doctorsMeStats),
      _api.getMap(ApiConstants.wallet),
      _api.getMap(ApiConstants.walletEarnings),
    ]);

    final user = results[0];
    final stats = results[1];
    final wallet = results[2];
    final earned = results[3];

    final appointments = Api.map(stats['appointments']);
    final currency = Api.str(wallet['currency'], 'USD');
    final name = Api.nameOf(user, 'Doctor');

    return DoctorDashboard(
      practitioner: Practitioner(
        name: name,
        initials: initialsOf(name),
        availableBalance: Api.majorUnits(wallet['balanceMinor']),
        currency: currency,
      ),
      pendingRequests: '${Api.integer(appointments['upcoming'])}',
      todaysPatients: '${Api.rows(stats['todayVisits']).length}',
      totalEarned: money(Api.majorUnits(earned['lifetimeMinor']), currency),
      totalPatients: '${Api.integer(appointments['total'])}',
      load: Api.rows(stats['load']).map(_dayLoadFrom).toList(),
      visits: Api.rows(stats['todayVisits']).map(_visitFrom).toList(),
    );
  }

  /// `{date: 2026-08-05, count: 1}` → a bar captioned `Wed`.
  DayLoad _dayLoadFrom(Map<String, dynamic> json) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final at = Api.date(json['date']);
    return DayLoad(
      dayLabel: names[(at.weekday - 1) % 7],
      count: Api.integer(json['count']),
    );
  }

  PatientVisit _visitFrom(Map<String, dynamic> json) {
    final name = Api.nameOf(json['patientId'], 'Patient');
    final appointment = doctorAppointmentFrom(json);
    return PatientVisit(
      patientName: name,
      initials: initialsOf(name),
      reason: appointment.complaint,
      timeLabel: appointment.timeLabel,
      // Anything the doctor has not yet accepted is still a request.
      status: Api.str(json['status']) == 'confirmed'
          ? VisitStatus.confirmed
          : VisitStatus.pending,
    );
  }

  // ─── Appointments ────────────────────────────────────────────────────────

  @override
  Future<List<DoctorAppointment>> appointments() async {
    final rows = await _api.getList(
      ApiConstants.appointments,
      query: _asDoctor,
    );
    return rows.map(doctorAppointmentFrom).toList();
  }

  @override
  Future<List<UploadedDocument>> patientDocuments(String appointmentId) async {
    // The doctor sees what the patient shared with them, not the patient's
    // whole vault — the server decides that, which is why this is the
    // shared-with-me list and not `vault/records`.
    final rows = await _api.getList(ApiConstants.vaultRecordsSharedWithMe);
    return rows.map(vaultRecordFrom).toList();
  }

  @override
  Future<void> cancelAppointment(String appointmentId, {String? reason}) async {
    await _api.post(
      ApiConstants.postAppointmentsCancel(appointmentId),
      body: {if (reason != null && reason.isNotEmpty) 'reason': reason},
    );
  }

  // ─── Earnings ────────────────────────────────────────────────────────────

  @override
  Future<DoctorEarnings> earnings() async {
    final results = await Future.wait([
      _api.getMap(ApiConstants.walletEarnings),
      _api.get(ApiConstants.walletTransactions, query: {'limit': _pageSize}),
      _api.get(ApiConstants.walletWithdrawals, query: {'limit': _pageSize}),
    ]);

    final summary = Api.map(results[0]);
    final currency = Api.str(summary['currency'], 'USD');

    // What has actually left the wallet, which the earnings summary does not
    // carry — it reports what is available and what is still pending.
    final paidOut = ApiClient.listFrom(results[2])
        .where((w) => Api.str(w['status']) == 'completed')
        .fold(0.0, (sum, w) => sum + Api.majorUnits(w['amountMinor']));

    final consultations = ApiClient.listFrom(results[1])
        .where((t) => Api.str(t['type']) == 'consultation_earning')
        .map((t) => _earningFrom(t, currency))
        .toList();

    return DoctorEarnings(
      availableLabel: money(
        Api.majorUnits(summary['availableMinor']),
        currency,
      ),
      totalEarnedLabel: money(
        Api.majorUnits(summary['lifetimeMinor']),
        currency,
      ),
      paidOutLabel: money(paidOut, currency),
      consultations: consultations,
    );
  }

  ConsultationEarning _earningFrom(Map<String, dynamic> json, String currency) {
    final amount = Api.majorUnits(json['amountMinor']);
    return ConsultationEarning(
      id: Api.id(json),
      // A transaction names the entry, not the person it came from; the
      // description is what the server wrote on it.
      patientName: Api.str(json['description'], 'Consultation'),
      earnedOn: Api.date(json['createdAt']),
      amountLabel: '+${money(amount, currency)}',
      // Money already credited to the balance has settled; only a withdrawal
      // is ever in flight.
      state: PayoutState.completed,
    );
  }

  @override
  Future<List<PayoutAccount>> payoutAccounts() async {
    final rows = await _api.getList(ApiConstants.walletPayoutAccounts);
    return rows.map((json) {
      final last4 = Api.str(json['last4']);
      final kind = Api.str(json['kind'], 'Account').replaceAll('_', ' ');
      return PayoutAccount(
        id: Api.id(json),
        label: last4.isEmpty ? kind : '$kind •••• $last4',
        isDefault: json['isDefault'] == true,
      );
    }).toList();
  }

  @override
  Future<void> requestWithdrawal({
    required double amount,
    String? payoutAccountId,
  }) async {
    await _api.post(
      ApiConstants.postWalletWithdrawals,
      body: {
        'amountMinor': (amount * 100).round(),
        if (payoutAccountId != null && payoutAccountId.isNotEmpty)
          'payoutAccountId': payoutAccountId,
      },
    );
  }

  // ─── Profile ─────────────────────────────────────────────────────────────

  @override
  Future<DoctorProfileDetails> profileDetails() async {
    final results = await Future.wait([
      _api.getMap(ApiConstants.usersMe),
      _api.getMap(ApiConstants.doctorsMe),
    ]);
    final user = results[0];
    final practice = results[1];

    final specialties = practice['specialties'];
    final languages = practice['languages'];

    return DoctorProfileDetails(
      fullName: Api.nameOf(user, 'Doctor'),
      email: Api.str(user['email']),
      specialty: specialties is List && specialties.isNotEmpty
          ? Api.str(specialties.first)
          : '',
      experience: '${Api.integer(practice['yearsOfExperience'])}',
      biography: Api.str(practice['bio']),
      licenceNumber: Api.str(practice['licenseNumber']),
      language: languages is List && languages.isNotEmpty
          ? Api.str(languages.first)
          : '',
      consultationFee: Api.majorUnits(practice['consultationFeeMinor']),
      currency: Api.str(practice['currency'], 'USD'),
      photoUrl: Api.avatarOf(user),
    );
  }

  @override
  Future<void> saveProfileDetails({
    required String specialty,
    required String experience,
    required String biography,
    required String licenceNumber,
    required String language,
  }) async {
    // `POST /doctors/me` upserts the practice profile — the same route creates
    // it and edits it, so there is no separate update path to choose between.
    await _api.post(
      ApiConstants.postDoctorsMe,
      body: {
        if (specialty.isNotEmpty) 'specialties': [specialty],
        if (language.isNotEmpty) 'languages': [language],
        if (experience.isNotEmpty)
          'yearsOfExperience': int.tryParse(experience.trim()) ?? 0,
        if (biography.isNotEmpty) 'bio': biography,
        if (licenceNumber.isNotEmpty) 'licenseNumber': licenceNumber,
      },
    );
  }

  @override
  Future<void> saveConsultationFee({
    required double amount,
    required String currency,
  }) async {
    await _api.post(
      ApiConstants.postDoctorsMe,
      body: {
        'consultationFeeMinor': (amount * 100).round(),
        'currency': currency,
      },
    );
  }

  // ─── Schedule ────────────────────────────────────────────────────────────

  @override
  Future<List<ScheduleDay>> availability(DateTime anchor) async {
    final practice = await _api.getMap(ApiConstants.doctorsMe);
    final windows = Api.rows(practice['availability']);

    // The server stores a weekly pattern, not dated days: one entry per
    // weekday it is open. The editor shows a specific week, so the pattern is
    // laid over the seven dates around [anchor].
    final monday = anchor.subtract(Duration(days: anchor.weekday - 1));

    return List.generate(7, (offset) {
      final date = monday.add(Duration(days: offset));
      // `DateTime.weekday` runs Monday 1..Sunday 7; the server runs Sunday 0.
      final dayOfWeek = date.weekday % 7;
      final open = windows
          .where((w) => Api.integer(w['dayOfWeek']) == dayOfWeek)
          .toList();

      return ScheduleDay(
        name: _weekdayNames[offset],
        dayOfMonth: date.day,
        dayOfWeek: dayOfWeek,
        isOpen: open.isNotEmpty,
        slots: open.expand(_slotsIn).toList(),
      );
    });
  }

  /// A window is a range plus a slot length: `09:00–17:00` at 30 minutes is
  /// sixteen chips, which is what the day card lists.
  List<TimeSlot> _slotsIn(Map<String, dynamic> window) {
    final start = Api.integer(window['startMinute']);
    final end = Api.integer(window['endMinute']);
    final step = Api.integer(window['slotDurationMinutes'], 30);
    if (step <= 0 || end <= start) return const [];

    return [
      for (var at = start; at + step <= end; at += step)
        TimeSlot.fromMinutes(at, at + step),
    ];
  }

  @override
  Future<void> saveAvailability(List<ScheduleDay> days) async {
    // Chips are contiguous slots of one length, so the shortest gap between
    // two of them is the slot length the day was built from. Sending the
    // window back as one range keeps the document the size the server expects
    // rather than one entry per chip.
    final windows = <Map<String, dynamic>>[];

    for (final day in days.where((d) => d.isOpen && d.slots.isNotEmpty)) {
      final slots = [...day.slots]
        ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
      final step = slots
          .map((s) => s.endMinute - s.startMinute)
          .reduce((a, b) => a < b ? a : b);

      windows.add({
        'dayOfWeek': day.dayOfWeek,
        'startMinute': slots.first.startMinute,
        'endMinute': slots.last.endMinute,
        'slotDurationMinutes': step <= 0 ? 30 : step,
      });
    }

    await _api.put(
      ApiConstants.putDoctorsMeAvailability,
      body: {'availability': windows},
    );
  }

  // ─── Orders ──────────────────────────────────────────────────────────────

  @override
  Future<void> prescribe({
    required String appointmentId,
    required List<PrescribedMedicine> medicines,
  }) async {
    await _api.post(
      ApiConstants.postConsultationsPrescriptions(appointmentId),
      body: {
        'items': [
          for (final medicine in medicines)
            {
              'medicineName': medicine.name,
              'dosage': medicine.doseLabel,
              'frequency': '${medicine.dailyDose} times daily',
              'durationDays': medicine.durationDays,
              if (medicine.instructions.isNotEmpty)
                'notes': medicine.instructions,
            },
        ],
      },
    );
  }

  /// Threads, named by joining them to the appointment list.
  ///
  /// `GET /consultations/threads` carries a bare `counterpartId`, so on its own
  /// every row would read as an id. The appointment list does populate the
  /// patient, and both are keyed by appointment — so the name comes from
  /// there. See docs/API-GAPS.md.
  @override
  Future<List<PatientThread>> threads() async {
    final results = await Future.wait([
      _api.getList(ApiConstants.consultationsThreads, query: {'limit': 100}),
      _api.getList(ApiConstants.appointments, query: _asDoctor),
    ]);

    final byAppointment = {
      for (final row in results[1]) Api.id(row): row,
    };

    return results[0].map((thread) {
      final appointmentId = Api.id(thread['appointmentId']);
      final booking = Api.map(byAppointment[appointmentId]);
      final name = Api.nameOf(booking['patientId'], 'Patient');
      final last = Api.map(thread['lastMessage']);

      return PatientThread(
        id: appointmentId,
        patientName: name,
        preview: Api.str(last['body']),
        timeLabel: _threadTimeLabel(Api.date(last['createdAt'])),
        unreadCount: Api.integer(thread['unread']),
        photoUrl: Api.avatarOf(booking['patientId']),
      );
    }).toList();
  }

  /// `18:31` — the thread list prints a 24-hour clock, unlike the bubbles.
  String _threadTimeLabel(DateTime at) =>
      '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}';

  /// Built from the appointment list, because a doctor's patients are exactly
  /// the people they have consulted and the server has no separate roster
  /// endpoint for them.
  ///
  /// Age and gender are not on an appointment, so the fields the design fills
  /// from a chart are left at their empty values rather than invented.
  @override
  Future<List<ReviewPatient>> reviewPatients() async {
    final rows = await _api.getList(
      ApiConstants.appointments,
      query: _asDoctor,
    );

    final byPatient = <String, ReviewPatient>{};
    for (final row in rows) {
      final id = Api.id(row['patientId']);
      if (id.isEmpty) continue;
      final seenOn = Api.date(row['slotStart']);

      // Newest consultation wins, which is what "last seen" means on the row.
      final existing = byPatient[id];
      if (existing != null && existing.seenOn.isAfter(seenOn)) continue;

      byPatient[id] = ReviewPatient(
        id: id,
        name: Api.nameOf(row['patientId'], 'Patient'),
        code: Api.id(row).length >= 6
            ? Api.id(row).substring(Api.id(row).length - 6).toUpperCase()
            : Api.id(row).toUpperCase(),
        age: 0,
        gender: '',
        complaint: Api.str(row['reason'], 'Consultation'),
        seenOn: seenOn,
      );
    }

    return byPatient.values.toList()
      ..sort((a, b) => b.seenOn.compareTo(a.seenOn));
  }

  @override
  Future<void> orderTest({
    required String patientId,
    required List<String> tests,
    String? notes,
    String? appointmentId,
  }) async {
    await _api.post(
      ApiConstants.postLabOrders,
      body: {
        'patientId': patientId,
        'tests': tests,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (appointmentId != null && appointmentId.isNotEmpty)
          'appointmentId': appointmentId,
      },
    );
  }
}

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
