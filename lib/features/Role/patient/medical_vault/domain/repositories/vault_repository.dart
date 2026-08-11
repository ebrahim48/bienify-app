import '../entities/medical_record.dart';

/// The patient's own medical history: prescriptions, documents and tests.
abstract class VaultRepository {
  /// Prescriptions a doctor has written, newest first.
  Future<List<DigitalPrescription>> prescriptions();

  /// Documents the patient has stored.
  Future<List<UploadedDocument>> documents();

  /// Diagnostic tests ordered for the patient.
  Future<List<TestOrder>> testOrders();

  /// Places where a test can be taken.
  Future<List<TestingCentre>> testingCentres();

  /// The patient's standing health information.
  Future<HealthProfile> healthProfile();

  Future<void> saveHealthProfile(HealthProfile profile);

  /// Lets [doctorUserId] read the record [recordId].
  ///
  /// Sharing is per-record and per-doctor: a patient hands over one document,
  /// not their whole history.
  Future<void> shareRecord({
    required String recordId,
    required String doctorUserId,
  });

  Future<void> revokeShare({
    required String recordId,
    required String doctorUserId,
  });
}

/// Standing clinical facts about the patient.
class HealthProfile {
  const HealthProfile({
    this.bloodGroup = '',
    this.heightCm,
    this.weightKg,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.currentMedications = const [],
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.notes = '',
  });

  final String bloodGroup;
  final double? heightCm;
  final double? weightKg;
  final List<String> allergies;
  final List<String> chronicConditions;
  final List<String> currentMedications;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String notes;

  bool get isEmpty =>
      bloodGroup.isEmpty &&
      allergies.isEmpty &&
      chronicConditions.isEmpty &&
      currentMedications.isEmpty;
}
