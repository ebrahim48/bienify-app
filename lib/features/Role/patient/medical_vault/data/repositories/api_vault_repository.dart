import '../../../../../../core/constants/api_constants.dart';
import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/network/mappers.dart';
import '../../domain/entities/medical_record.dart';
import '../../domain/repositories/vault_repository.dart';

/// The medical vault, served by the API.
class ApiVaultRepository implements VaultRepository {
  const ApiVaultRepository(this._api);

  final ApiClient _api;

  static const int _pageSize = 100;

  @override
  Future<List<DigitalPrescription>> prescriptions() async {
    final rows = await _api.getList(
      ApiConstants.prescriptions,
      query: {'limit': _pageSize},
    );
    final items = rows.map(prescriptionFrom).toList()
      ..sort((a, b) => b.issuedOn.compareTo(a.issuedOn));
    return items;
  }

  @override
  Future<List<UploadedDocument>> documents() async {
    final rows = await _api.getList(
      ApiConstants.vaultRecords,
      query: {'limit': _pageSize},
    );
    final items = rows.map(vaultRecordFrom).toList()
      ..sort((a, b) => b.uploadedOn.compareTo(a.uploadedOn));
    return items;
  }

  @override
  Future<List<TestOrder>> testOrders() async {
    final rows = await _api.getList(
      ApiConstants.labOrders,
      query: {'limit': _pageSize},
    );
    return rows.map(testOrderFrom).toList();
  }

  @override
  Future<List<TestingCentre>> testingCentres() async {
    final rows = await _api.getList(
      ApiConstants.testingCentres,
      query: {'limit': _pageSize},
    );
    return rows.map(testingCentreFrom).toList();
  }

  @override
  Future<HealthProfile> healthProfile() async {
    final json = await _api.getMap(ApiConstants.vaultHealthProfile);
    return HealthProfile(
      bloodGroup: Api.str(json['bloodGroup']),
      heightCm: json['heightCm'] == null ? null : Api.decimal(json['heightCm']),
      weightKg: json['weightKg'] == null ? null : Api.decimal(json['weightKg']),
      allergies: _strings(json['allergies']),
      chronicConditions: _strings(json['chronicConditions']),
      currentMedications: _strings(json['currentMedications']),
      emergencyContactName: Api.str(json['emergencyContactName']),
      emergencyContactPhone: Api.str(json['emergencyContactPhone']),
      notes: Api.str(json['notes']),
    );
  }

  @override
  Future<void> saveHealthProfile(HealthProfile profile) async {
    await _api.put(
      ApiConstants.putVaultHealthProfile,
      // Every field is optional server-side, and sending an empty string for
      // an unset blood group fails its enum check — so only what the patient
      // actually filled in is sent.
      body: {
        if (profile.bloodGroup.isNotEmpty) 'bloodGroup': profile.bloodGroup,
        if (profile.heightCm != null) 'heightCm': profile.heightCm,
        if (profile.weightKg != null) 'weightKg': profile.weightKg,
        'allergies': profile.allergies,
        'chronicConditions': profile.chronicConditions,
        'currentMedications': profile.currentMedications,
        if (profile.emergencyContactName.isNotEmpty)
          'emergencyContactName': profile.emergencyContactName,
        if (profile.emergencyContactPhone.isNotEmpty)
          'emergencyContactPhone': profile.emergencyContactPhone,
        if (profile.notes.isNotEmpty) 'notes': profile.notes,
      },
    );
  }

  @override
  Future<void> shareRecord({
    required String recordId,
    required String doctorUserId,
  }) async {
    await _api.post(
      ApiConstants.postVaultRecordsShare(recordId),
      body: {'doctorUserId': doctorUserId},
    );
  }

  @override
  Future<void> revokeShare({
    required String recordId,
    required String doctorUserId,
  }) async {
    await _api.delete(
      ApiConstants.deleteVaultRecordsShareDoctoruserid(recordId, doctorUserId),
    );
  }

  static List<String> _strings(dynamic v) =>
      v is List ? v.map(Api.str).where((s) => s.isNotEmpty).toList() : const [];
}
