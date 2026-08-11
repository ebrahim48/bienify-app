import '../../domain/entities/appointment.dart';

/// Sample bookings behind the Appointments tab.
///
/// Static by design — this feature is UI-first, so there is no repository or
/// API here; the shapes are what a future endpoint will fill in.
class AppointmentMockData {
  AppointmentMockData._();

  static const String _doctor = 'Dr. Kwame Mensah';

  /// The consultation fee the design shows on the payment summary.
  static const double _fee = 400;

  static const String _specialty = 'Pediatrician';

  /// One appointment today (joinable) plus two later ones, matching the
  /// "Today" / "23 February" grouping in the design.
  ///
  /// [now] is injectable so goldens can pin the date — otherwise the first
  /// card's heading changes every midnight and the image never matches twice.
  static List<Appointment> upcoming({DateTime? now}) {
    now ??= DateTime.now();
    return [
      Appointment(
        id: 'appt-today',
        doctorName: _doctor,
        specialty: _specialty,
        scheduledAt: DateTime(now.year, now.month, now.day, 10),
        consultationFee: _fee,
      ),
      Appointment(
        id: 'appt-2',
        doctorName: _doctor,
        specialty: _specialty,
        scheduledAt: DateTime(2026, 2, 23, 10),
        consultationFee: _fee,
      ),
      Appointment(
        id: 'appt-3',
        doctorName: _doctor,
        specialty: _specialty,
        scheduledAt: DateTime(2026, 2, 23, 14, 30),
        consultationFee: _fee,
      ),
    ];
  }

  static List<Appointment> past() => [
    for (var index = 0; index < 3; index++)
      Appointment(
        id: 'appt-past-$index',
        doctorName: _doctor,
        specialty: _specialty,
        scheduledAt: DateTime(2026, 4, 1, 10),
        consultationFee: _fee,
        status: AppointmentStatus.completed,
      ),
  ];

  static List<Appointment> cancelled() => [
    for (var index = 0; index < 3; index++)
      Appointment(
        id: 'appt-cancelled-$index',
        doctorName: _doctor,
        specialty: _specialty,
        scheduledAt: DateTime(2026, 4, 1, 10),
        consultationFee: _fee,
        status: AppointmentStatus.cancelled,
      ),
  ];

  static List<Appointment> all({DateTime? now}) => [
    ...upcoming(now: now),
    ...past(),
    ...cancelled(),
  ];
}
