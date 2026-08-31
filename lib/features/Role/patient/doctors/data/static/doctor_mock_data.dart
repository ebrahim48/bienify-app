import '../../domain/entities/doctor_category.dart';
import '../../domain/entities/doctor_details.dart';
import '../models/doctor_model.dart';

/// Sample directory content mirroring the Search and Doctor Details designs.
class DoctorMockData {
  DoctorMockData._();

  /// Sample practitioners.
  ///
  /// `patientsSeen` is carried because the live app shows it — the Doctor
  /// Details stat tile and the list card both read it — and a fixture without
  /// one would render a screen no real doctor produces. The values descend
  /// with the review counts, the way a real directory's would.
  static const List<DoctorModel> doctors = [
    DoctorModel(
      id: 'doc-1',
      name: 'Dr.Anjelica Peacock,MD',
      specialty: 'Phychologist',
      rating: 4.8,
      reviewCount: 220,
      patientsSeen: 2700,
      consultationFee: 400,
    ),
    DoctorModel(
      id: 'doc-2',
      name: 'Dr.Brian Thompson,DO',
      specialty: 'Cardiologist',
      rating: 4.6,
      reviewCount: 180,
      patientsSeen: 1400,
      consultationFee: 350,
    ),
    DoctorModel(
      id: 'doc-3',
      name: 'Dr.Sophia Martinez,MSW',
      specialty: 'Dentists',
      rating: 4.9,
      reviewCount: 150,
      patientsSeen: 860,
      consultationFee: 300,
    ),
    DoctorModel(
      id: 'doc-4',
      name: 'Dr.James Robinson,DDS',
      specialty: 'Orthodontists',
      rating: 4.7,
      reviewCount: 120,
      patientsSeen: 430,
      consultationFee: 320,
    ),
    DoctorModel(
      id: 'doc-5',
      name: 'Dr.Linda Chen,DMD',
      specialty: 'Pediatric Dentists',
      rating: 4.8,
      reviewCount: 95,
      patientsSeen: 95,
      consultationFee: 280,
    ),
  ];

  /// The catch-all shown full-width at the top of "Find a doctor", and the
  /// default selection.
  static const DoctorCategory generalCategory = DoctorCategory(
    id: 'general',
    name: 'General',
  );

  /// The specialty grid beneath it.
  ///
  /// The design repeats "Orology"/"Oncology" to fill the grid; real
  /// specialties are used here instead, and "Urology" is spelled correctly.
  static const List<DoctorCategory> categories = [
    DoctorCategory(id: 'internal-medicine', name: 'Internal Medicine'),
    DoctorCategory(id: 'neuromedicine', name: 'Neuromedicine'),
    DoctorCategory(id: 'general-physician', name: 'General Physician'),
    DoctorCategory(id: 'gastroenterology', name: 'Gastroenterology'),
    DoctorCategory(id: 'urology', name: 'Urology'),
    DoctorCategory(id: 'oncology', name: 'Oncology'),
    DoctorCategory(id: 'cardiology', name: 'Cardiology'),
    DoctorCategory(id: 'dermatology', name: 'Dermatology'),
    DoctorCategory(id: 'pediatrics', name: 'Pediatrics'),
    DoctorCategory(id: 'orthopedics', name: 'Orthopedics'),
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
