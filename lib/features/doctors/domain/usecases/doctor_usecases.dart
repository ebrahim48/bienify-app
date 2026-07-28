import '../entities/doctor.dart';
import '../entities/doctor_details.dart';
import '../repositories/doctor_repository.dart';

/// Searches the doctor directory.
class SearchDoctors {
  const SearchDoctors(this._repository);

  final DoctorRepository _repository;

  Future<List<Doctor>> call({String query = '', String? specialty}) =>
      _repository.search(query: query, specialty: specialty);
}

/// Loads the specialty filter chips.
class GetSpecialties {
  const GetSpecialties(this._repository);

  final DoctorRepository _repository;

  Future<List<String>> call() => _repository.getSpecialties();
}

/// Loads a full doctor profile.
class GetDoctorDetails {
  const GetDoctorDetails(this._repository);

  final DoctorRepository _repository;

  Future<DoctorDetails> call(String doctorId) =>
      _repository.getDetails(doctorId);
}

/// Loads bookable days and slots.
class GetDoctorAvailability {
  const GetDoctorAvailability(this._repository);

  final DoctorRepository _repository;

  Future<DoctorAvailability> call(String doctorId) =>
      _repository.getAvailability(doctorId);
}
