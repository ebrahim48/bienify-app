/// Lifecycle of a booking.
enum AppointmentStatus { upcoming, completed, cancelled }

/// The three tabs on the Appointments screen.
enum AppointmentTab { upcoming, past, cancelled }

/// A date heading plus the appointments filed under it, e.g. `Today` or
/// `23 February`.
class AppointmentGroup {
  const AppointmentGroup({required this.label, required this.items});

  final String label;
  final List<Appointment> items;
}

/// A scheduled consultation.
class Appointment {
  const Appointment({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.scheduledAt,
    this.status = AppointmentStatus.upcoming,
    this.doctorPhotoUrl,
    this.consultationFee = 0,
  });

  final String id;
  final String doctorName;
  final String specialty;
  final DateTime scheduledAt;
  final AppointmentStatus status;
  final String? doctorPhotoUrl;

  /// What the consultation costs, in major units.
  ///
  /// The server decides the fee and sends it with the appointment, so the
  /// payment screen shows what will actually be charged rather than a figure
  /// the client worked out for itself.
  final double consultationFee;

  /// A video room only opens shortly before the slot, so the Join affordance
  /// is a property of the appointment rather than of the button.
  bool get canJoin =>
      status == AppointmentStatus.upcoming &&
      scheduledAt.difference(DateTime.now()) <= const Duration(minutes: 15);
}
