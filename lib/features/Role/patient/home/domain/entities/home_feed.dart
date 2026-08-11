import '../../../appointments/domain/entities/appointment.dart';
import '../../../doctors/domain/entities/doctor.dart';
import 'lab_request.dart';

/// Everything the Home screen renders, fetched as one payload.
///
/// Modelled as a single aggregate rather than four independent calls so the
/// screen has one loading state and one error state instead of four.
class HomeFeed {
  const HomeFeed({
    required this.patientName,
    required this.location,
    this.labRequests = const [],
    this.upcomingAppointments = const [],
    this.nearbyDoctors = const [],
    this.unreadAppointments = 0,
    this.unreadMessages = 0,
    this.unreadNotifications = 0,
  });

  const HomeFeed.empty() : this(patientName: '', location: '');

  final String patientName;

  /// Human-readable place, e.g. `Los Angels, USA`.
  final String location;

  final List<LabRequest> labRequests;
  final List<Appointment> upcomingAppointments;
  final List<Doctor> nearbyDoctors;

  /// Badge counts for the bottom navigation and header actions.
  final int unreadAppointments;
  final int unreadMessages;
  final int unreadNotifications;

  bool get isEmpty =>
      labRequests.isEmpty &&
      upcomingAppointments.isEmpty &&
      nearbyDoctors.isEmpty;
}
