import '../../../../../../core/constants/api_constants.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/network/mappers.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/entities/doctor_details.dart';
import '../../domain/repositories/doctor_repository.dart';

/// Doctor discovery, served by the API.
class ApiDoctorRepository implements DoctorRepository {
  const ApiDoctorRepository(this._api);

  final ApiClient _api;

  /// How far ahead the calendar offers appointments.
  ///
  /// The server refuses a slot search wider than 31 days — an unbounded range
  /// would have it generating slots forever.
  static const Duration _bookingWindow = Duration(days: 28);

  @override
  Future<List<Doctor>> search({String query = '', String? specialty}) async {
    final term = query.trim();
    final rows = await _api.getList(
      ApiConstants.doctors,
      query: {
        if (term.isNotEmpty) 'search': term,
        if (specialty != null && specialty.isNotEmpty) 'specialty': specialty,
        'limit': 50,
      },
    );
    return rows.map(doctorFrom).toList();
  }

  @override
  Future<List<String>> getSpecialties() async {
    // There is no specialty endpoint; the chips come from what the listed
    // doctors actually practise, so a chip never returns an empty result.
    final rows = await _api.getList(
      ApiConstants.doctors,
      query: {'limit': 100},
    );
    final found = <String>{};
    for (final row in rows) {
      final specialties = row['specialties'];
      if (specialties is List) {
        found.addAll(specialties.map(Api.str).where((s) => s.isNotEmpty));
      }
    }
    final sorted = found.toList()..sort();
    return sorted;
  }

  @override
  Future<DoctorDetails> getDetails(String doctorId) async {
    final json = await _api.getMap(ApiConstants.doctors2(doctorId));
    if (json.isEmpty) throw NotFoundException('Unknown doctor $doctorId');

    final languages = json['languages'];
    return DoctorDetails(
      doctor: doctorFrom(json),
      experienceYears: Api.integer(json['yearsOfExperience']),
      // The server does not count a doctor's patients; showing a fabricated
      // number would be worse than showing none.
      patientCount: '—',
      workingTime: _workingTime(json['availability']),
      // Named, not coded: the tile used to read "en".
      languages: languages is List
          ? languages.map(Api.languageName).where((s) => s.isNotEmpty).toList()
          : const [],
      biography: Api.str(json['bio']),
      heroImage: Api.avatarOf(json['userId']),
    );
  }

  @override
  Future<DoctorAvailability> getAvailability(String doctorId) async {
    final from = DateTime.now();
    final to = from.add(_bookingWindow);

    final data = await _api.getMap(
      ApiConstants.appointmentsSlots,
      query: {
        'doctorProfileId': doctorId,
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );

    // The server returns a flat list of free windows; the calendar groups them
    // by day. Anything already taken is simply absent, so every slot here is
    // bookable.
    final byDay = <DateTime, List<TimeSlot>>{};
    for (final slot in Api.rows(data['slots'])) {
      final start = Api.date(slot['start']).toLocal();
      final day = DateTime(start.year, start.month, start.day);
      byDay.putIfAbsent(day, () => []).add(TimeSlot(label: _clock(start)));
    }

    final days =
        byDay.entries
            .map((e) => AvailableDay(date: e.key, slots: e.value))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    return DoctorAvailability(
      year: from.year,
      months: _monthsSpanned(from, to),
      selectedMonth: _monthName(from.month),
      days: days,
    );
  }

  /// A human summary of the weekly pattern, e.g. `Mon - Fri, 09:00 - 17:00`.
  static String _workingTime(dynamic availability) {
    final rows = Api.rows(availability);
    if (rows.isEmpty) return 'By appointment';

    final days = rows.map((r) => Api.integer(r['dayOfWeek'])).toSet().toList()
      ..sort();
    final open = rows
        .map((r) => Api.integer(r['startMinute']))
        .reduce((a, b) => a < b ? a : b);
    final close = rows
        .map((r) => Api.integer(r['endMinute']))
        .reduce((a, b) => a > b ? a : b);

    // A doctor available every day at every hour is the seed default; calling
    // that "Sun - Sat, 00:00 - 24:00" reads as broken rather than generous.
    if (days.length == 7 && open == 0 && close >= 1440) return 'Any time';

    final span = days.length == 1
        ? _weekday(days.first)
        : '${_weekday(days.first)} - ${_weekday(days.last)}';
    return '$span, ${_minutes(open)} - ${_minutes(close)}';
  }

  static String _weekday(int dayOfWeek) => switch (dayOfWeek) {
    0 => 'Sun',
    1 => 'Mon',
    2 => 'Tue',
    3 => 'Wed',
    4 => 'Thu',
    5 => 'Fri',
    _ => 'Sat',
  };

  static String _minutes(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  static String _clock(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static List<String> _monthsSpanned(DateTime from, DateTime to) {
    final months = <String>[];
    var cursor = DateTime(from.year, from.month);
    while (!cursor.isAfter(DateTime(to.year, to.month))) {
      months.add(_monthName(cursor.month));
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return months;
  }

  static String _monthName(int month) => const [
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
  ][month - 1];
}
