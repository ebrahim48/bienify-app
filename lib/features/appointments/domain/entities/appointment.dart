/// Lifecycle of a booking.
enum AppointmentStatus { upcoming, completed, cancelled }

/// A scheduled consultation.
class Appointment {
  const Appointment({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.scheduledAt,
    this.status = AppointmentStatus.upcoming,
    this.doctorPhotoUrl,
  });

  final String id;
  final String doctorName;
  final String specialty;
  final DateTime scheduledAt;
  final AppointmentStatus status;
  final String? doctorPhotoUrl;

  /// A video room only opens shortly before the slot, so the Join affordance
  /// is a property of the appointment rather than of the button.
  bool get canJoin =>
      status == AppointmentStatus.upcoming &&
      scheduledAt.difference(DateTime.now()) <= const Duration(minutes: 15);
}
