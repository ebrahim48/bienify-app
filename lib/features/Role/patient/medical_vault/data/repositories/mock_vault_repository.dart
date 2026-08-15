import '../../domain/entities/medical_record.dart';
import '../../domain/repositories/vault_repository.dart';
import '../static/medical_mock_data.dart';

/// In-memory vault data, so goldens render a known history.
///
/// Resolves immediately, for the same reason as the pharmacy fixture: a fake
/// delay makes a golden capture an empty screen.
class MockVaultRepository implements VaultRepository {
  MockVaultRepository();

  HealthProfile _profile = const HealthProfile(
    bloodGroup: 'O+',
    allergies: ['Penicillin'],
  );

  @override
  Future<List<DigitalPrescription>> prescriptions() async {
    return MedicalMockData.prescriptions();
  }

  @override
  Future<List<UploadedDocument>> documents() async {
    return MedicalMockData.uploads();
  }

  @override
  Future<UploadedDocument> uploadDocument({
    required List<int> bytes,
    required String fileName,
    required String contentType,
    required String title,
    required VaultRecordType type,
  }) async {
    return UploadedDocument(
      id: 'mock-upload-${DateTime.now().microsecondsSinceEpoch}',
      fileName: title,
      kindLabel: 'Document',
      uploadedOn: DateTime.now(),
    );
  }

  @override
  Future<List<TestOrder>> testOrders() async {
    return MedicalMockData.testOrders;
  }

  @override
  Future<List<TestingCentre>> testingCentres() async {
    return MedicalMockData.centres;
  }

  @override
  Future<HealthProfile> healthProfile() async {
    return _profile;
  }

  @override
  Future<void> saveHealthProfile(HealthProfile profile) async {
    _profile = profile;
  }

  @override
  Future<void> shareRecord({
    required String recordId,
    required String doctorUserId,
  }) async {}

  @override
  Future<void> revokeShare({
    required String recordId,
    required String doctorUserId,
  }) async {}

  @override
  Future<void> uploadLabResult({
    required String labOrderId,
    required String path,
    required String fileName,
    required String mimeType,
    String? notes,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(1);
  }

  @override
  Future<void> selectTestingCentre({
    required String labOrderId,
    required String testingCentreId,
  }) async {}

  @override
  Future<void> respondToLabOrder({
    required String labOrderId,
    required bool accept,
  }) async {}

  @override
  Future<UploadedDocument> uploadDocument({
    required String path,
    required String fileName,
    required String mimeType,
    required VaultRecordType type,
    String? notes,
    void Function(double progress)? onProgress,
  }) async {
    // Reports the file the caller actually picked rather than a fixture, so a
    // golden or a demo shows the real name the patient chose.
    onProgress?.call(1);
    return UploadedDocument(
      id: 'mock-${DateTime.now().microsecondsSinceEpoch}',
      fileName: fileName,
      kindLabel: type.name,
      uploadedOn: DateTime.now(),
    );
  }
}
