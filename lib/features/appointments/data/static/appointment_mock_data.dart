import '../../domain/entities/appointment.dart';

/// Sample bookings behind the Appointments tab.
///
/// Static by design — this feature is UI-first, so there is no repository or
/// API here; the shapes are what a future endpoint will fill in.
class AppointmentMockData {
  AppointmentMockData._();

  static const String _doctor = 'Dr. Kwame Mensah';
  static const String _specialty = 'Pediatrician';

  /// One appointment today (joinable) plus two later ones, matching the
  /// "Today" / "23 February" grouping in the design.
  static List<Appointment> upcoming() {
    final now = DateTime.now();
    return [
      Appointment(
        id: 'appt-today',
        doctorName: _doctor,
        specialty: _specialty,
        scheduledAt: DateTime(now.year, now.month, now.day, 10),
      ),
      Appointment(
        id: 'appt-2',
        doctorName: _doctor,
        specialty: _specialty,
        scheduledAt: DateTime(2026, 2, 23, 10),
      ),
      Appointment(
        id: 'appt-3',
        doctorName: _doctor,
        specialty: _specialty,
        scheduledAt: DateTime(2026, 2, 23, 14, 30),
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
        status: AppointmentStatus.cancelled,
      ),
  ];

  static List<Appointment> all() => [...upcoming(), ...past(), ...cancelled()];
}
