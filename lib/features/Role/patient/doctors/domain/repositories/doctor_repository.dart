import '../entities/doctor.dart';
import '../entities/doctor_details.dart';

/// Doctor discovery and profiles.
abstract class DoctorRepository {
  /// Free-text and/or specialty search. An empty [query] with a null
  /// [specialty] returns the full listing.
  Future<List<Doctor>> search({String query, String? specialty});

  /// Specialty filter chips, excluding the leading "All".
  Future<List<String>> getSpecialties();

  Future<DoctorDetails> getDetails(String doctorId);

  /// Bookable days and slots for [doctorId].
  Future<DoctorAvailability> getAvailability(String doctorId);
}
