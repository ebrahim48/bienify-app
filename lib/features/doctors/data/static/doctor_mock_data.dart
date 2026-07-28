import '../../domain/entities/doctor_details.dart';
import '../models/doctor_model.dart';

/// Sample directory content mirroring the Search and Doctor Details designs.
class DoctorMockData {
  DoctorMockData._();

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

  /// Filter chips on the search screen; the UI prepends "All".
  static const List<String> specialties = [
    'General',
    'Psychologist',
    'Pediatrician',
    'Dermatologist',
    'Cardiologist',
  ];

  /// The profile shown in the Doctor Details design.
  static DoctorDetails detailsFor(DoctorModel doctor) => DoctorDetails(
    doctor: doctor,
    experienceYears: 8,
    patientCount: '2.7k+',
    workingTime: 'Sun-Sat, 9AM - 5PM',
    languages: const ['English'],
    biography:
        'Dr. Arafat Rahman is an experienced neurologist with 8+ years of '
        'expertise in treating stroke, migraine, and epilepsy. He focuses on '
        'accurate diagnosis and provides patient-centered care to improve '
        'overall neurological health',
  );

  static const List<String> months = [
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<TimeSlot> slots = [
    TimeSlot(label: '10:30 AM'),
    TimeSlot(label: '11:00 AM', isBooked: true),
    TimeSlot(label: '11:30 AM'),
    TimeSlot(label: '12:30 AM'),
    TimeSlot(label: '02:30 AM'),
  ];

  /// Five consecutive days in the selected month, as in the design strip.
  static DoctorAvailability availability() {
    const year = 2025;
    const month = 11;
    return DoctorAvailability(
      year: year,
      months: months,
      selectedMonth: 'November',
      days: [
        for (var day = 3; day <= 7; day++)
          AvailableDay(date: DateTime(year, month, day), slots: slots),
      ],
    );
  }
}
