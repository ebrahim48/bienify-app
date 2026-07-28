import '../../../../core/exceptions/app_exceptions.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/entities/doctor_details.dart';
import '../../domain/repositories/doctor_repository.dart';
import '../static/doctor_mock_data.dart';

/// Mock-backed implementation of [DoctorRepository].
///
/// Mirrors the auth and home features: the contract is what the app depends
/// on, and swapping in a Dio-backed data source touches only this file and
/// `DependencyInjection`.
class DoctorRepositoryImpl implements DoctorRepository {
  const DoctorRepositoryImpl();

  static const Duration _latency = Duration(milliseconds: 300);

  @override
  Future<List<Doctor>> search({String query = '', String? specialty}) async {
    await Future<void>.delayed(_latency);

    final term = query.trim().toLowerCase();
    final filter = specialty?.toLowerCase();

    return DoctorMockData.doctors.where((doctor) {
      final matchesQuery =
          term.isEmpty ||
          doctor.name.toLowerCase().contains(term) ||
          doctor.specialty.toLowerCase().contains(term);
      final matchesSpecialty =
          filter == null ||
          doctor.specialty.toLowerCase().contains(filter) ||
          // The design's chips are broader than the stored specialty strings
          // ("Psychologist" vs "Phychologist"), so match on the stem too.
          filter.contains(doctor.specialty.toLowerCase());
      return matchesQuery && matchesSpecialty;
    }).toList();
  }

  @override
  Future<List<String>> getSpecialties() async {
    await Future<void>.delayed(_latency);
    return DoctorMockData.specialties;
  }

  @override
  Future<DoctorDetails> getDetails(String doctorId) async {
    await Future<void>.delayed(_latency);
    final doctor = DoctorMockData.doctors
        .where((candidate) => candidate.id == doctorId)
        .firstOrNull;
    if (doctor == null) throw NotFoundException('Unknown doctor $doctorId');
    return DoctorMockData.detailsFor(doctor);
  }

  @override
  Future<DoctorAvailability> getAvailability(String doctorId) async {
    await Future<void>.delayed(_latency);
    return DoctorMockData.availability();
  }
}
