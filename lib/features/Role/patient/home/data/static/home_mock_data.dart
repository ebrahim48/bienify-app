import '../../../appointments/domain/entities/appointment.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/entities/lab_request.dart';
import '../../../doctors/data/models/doctor_model.dart';

/// Sample content mirroring the Home design, used by the mock data source
/// until the API is live.
///
/// Photo URLs are intentionally absent so `AppAvatar` renders monograms — a
/// missing network image would look broken, a monogram looks deliberate.
class HomeMockData {
  HomeMockData._();

  static const String patientName = 'Mahmudul Hasan';
  static const String location = 'Los Angels, USA';

  static const List<LabRequest> labRequests = [
    LabRequest(
      id: 'lab-1',
      category: 'Laboratory',
      priority: 'Routine',
      title: 'Complete Blood Count • CBC with Differential',
      requestedBy: 'Dr. Reed',
    ),
  ];

  static List<Appointment> get upcomingAppointments => [
    Appointment(
      id: 'appt-1',
      doctorName: 'Dr. Kwame Mensah',
      specialty: 'Pediatrician',
      scheduledAt: DateTime(2026, 4, 1, 10),
    ),
  ];

  static const List<DoctorModel> doctors = [
    DoctorModel(
      id: 'doc-1',
      name: 'Dr.Anjelica Peacock,MD',
      specialty: 'Phychologist',
      rating: 4.8,
      reviewCount: 220,
      consultationFee: 400,
    ),
    DoctorModel(
      id: 'doc-2',
      name: 'Dr.Brian Thompson,DO',
      specialty: 'Cardiologist',
      rating: 4.6,
      reviewCount: 180,
      consultationFee: 350,
    ),
    DoctorModel(
      id: 'doc-3',
      name: 'Dr.Sophia Martinez,MSW',
      specialty: 'Dentists',
      rating: 4.9,
      reviewCount: 150,
      consultationFee: 300,
    ),
    DoctorModel(
      id: 'doc-4',
      name: 'Dr.James Robinson,DDS',
      specialty: 'Orthodontists',
      rating: 4.7,
      reviewCount: 120,
      consultationFee: 320,
    ),
    DoctorModel(
      id: 'doc-5',
      name: 'Dr.Linda Chen,DMD',
      specialty: 'Pediatric Dentists',
      rating: 4.8,
      reviewCount: 95,
      consultationFee: 280,
    ),
  ];

  /// Filter chips on the search screen; `All` is prepended by the UI.
  static const List<String> specialties = [
    'General',
    'Psychologist',
    'Pediatrician',
    'Dermatologist',
    'Cardiologist',
  ];

  static HomeFeed get feed => HomeFeed(
    patientName: patientName,
    location: location,
    labRequests: labRequests,
    upcomingAppointments: upcomingAppointments,
    nearbyDoctors: doctors,
    unreadAppointments: 1,
    unreadMessages: 2,
    unreadNotifications: 3,
  );
}
