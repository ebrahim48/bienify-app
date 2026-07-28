import '../../domain/entities/appointment.dart';

/// Sample bookings backing the Appointments tab.
class AppointmentMockData {
  AppointmentMockData._();

  static List<Appointment> all() => [
    Appointment(
      id: 'appt-1',
      doctorName: 'Dr. Kwame Mensah',
      specialty: 'Pediatrician',
      scheduledAt: DateTime(2026, 4, 1, 10),
    ),
    Appointment(
      id: 'appt-2',
      doctorName: 'Dr.Anjelica Peacock,MD',
      specialty: 'Phychologist',
      scheduledAt: DateTime(2026, 4, 9, 14, 30),
    ),
    Appointment(
      id: 'appt-3',
      doctorName: 'Dr.Brian Thompson,DO',
      specialty: 'Cardiologist',
      scheduledAt: DateTime(2026, 3, 12, 9),
      status: AppointmentStatus.completed,
    ),
    Appointment(
      id: 'appt-4',
      doctorName: 'Dr.Sophia Martinez,MSW',
      specialty: 'Dentists',
      scheduledAt: DateTime(2026, 2, 28, 16),
      status: AppointmentStatus.cancelled,
    ),
  ];
}
