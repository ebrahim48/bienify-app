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
}
