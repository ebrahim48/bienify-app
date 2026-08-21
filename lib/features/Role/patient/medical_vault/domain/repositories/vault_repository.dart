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

  /// Stores a file the patient picked and files it in the vault.
  ///
  /// Two steps behind one call, because that is one operation from the
  /// caller's side and a half-done version of it is a bug: the bytes go
  /// straight to S3 against a presigned URL, then the record is created
  /// against the key that came back. The API never sees the file itself.
  Future<UploadedDocument> uploadDocument({
    required String path,
    required String fileName,
    required String mimeType,
    required VaultRecordType type,
    String? notes,
    void Function(double progress)? onProgress,
  });
}

/// What kind of document is being filed, matching the server's record types.
///
/// A closed set rather than a free string: the server rejects anything else,
/// and a typo here would only surface as a validation failure at the end of
/// an upload the patient already waited for.
enum VaultRecordType {
  labReport('lab_report'),
  imaging('imaging'),
  prescriptionScan('prescription_scan'),
  dischargeSummary('discharge_summary'),
  vaccination('vaccination'),
  other('other');

  const VaultRecordType(this.wireName);

  final String wireName;
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
