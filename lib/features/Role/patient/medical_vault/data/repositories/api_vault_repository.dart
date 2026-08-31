import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import 'dart:io';

import '../../../../../../core/constants/api_constants.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/network/attachment_uploader.dart';
import '../../../../../../core/network/mappers.dart';
import '../../domain/entities/medical_record.dart';
import '../../domain/repositories/vault_repository.dart';

/// The medical vault, served by the API.
class ApiVaultRepository implements VaultRepository {
  const ApiVaultRepository(this._api, this._uploader);

  final ApiClient _api;

  /// Shared with chat attachments: the same bucket, the same presigned PUT,
  /// the same streaming and expiry handling.
  final AttachmentUploader _uploader;

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
    // The order sheet names the patient and prints their date of birth, and a
    // patient's own listing does not populate them — they are the caller. Read
    // once here rather than per row.
    final results = await Future.wait([
      _api.getList(ApiConstants.labOrders, query: {'limit': _pageSize}),
      _api.getMap(ApiConstants.usersMe),
    ]);
    final rows = results[0] as List<Map<String, dynamic>>;
    final me = results[1] as Map<String, dynamic>;

    final name = Api.nameOf(me, AppStrings.you.tr);
    final dob = me['dob'] == null ? null : Api.date(me['dob']);

    return rows
        .map((row) => testOrderFrom(row, patientName: name, patientDob: dob))
        .toList();
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
  Future<({String url, String fileName})> recordDownloadUrl(
    String recordId,
  ) async {
    final data = await _api.getMap(
      ApiConstants.vaultRecordsDownloadUrl(recordId),
    );
    return (
      url: Api.str(data['url']),
      fileName: Api.str(data['fileName'], 'document'),
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

  @override
  Future<UploadedDocument> uploadDocument({
    required String path,
    required String fileName,
    required String mimeType,
    required VaultRecordType type,
    String? notes,
    void Function(double progress)? onProgress,
  }) async {
    final file = File(path);
    final size = await file.length();

    // The server signs a key of its own choosing, scoped to the caller — a
    // client cannot pick where its upload lands.
    final issued = await _api.postMap(
      ApiConstants.postVaultRecordsUploadUrl,
      body: {'contentType': mimeType},
    );

    final url = '${issued['url'] ?? ''}';
    final key = '${issued['key'] ?? ''}';
    if (url.isEmpty || key.isEmpty) {
      throw UnknownException('The server did not issue an upload location');
    }

    await _uploader.putBytes(
      url: url,
      file: file,
      mime: mimeType,
      size: size,
      onProgress: onProgress,
    );

    // Only now is the record created. Doing it the other way round would file
    // a document in the patient's vault that points at bytes which may never
    // have arrived.
    final created = await _api.postMap(
      ApiConstants.postVaultRecords,
      body: {
        'type': type.wireName,
        'title': fileName,
        's3Key': key,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );

    return vaultRecordFrom(created);
  }

  @override
  Future<void> uploadLabResult({
    required String labOrderId,
    required String path,
    required String fileName,
    required String mimeType,
    String? notes,
    void Function(double progress)? onProgress,
  }) async {
    final file = File(path);
    final size = await file.length();

    // Scoped by the server to the *order's* patient, not the caller — which is
    // why this is a different endpoint from the vault's own upload-url.
    final issued = await _api.postMap(
      ApiConstants.postLabOrdersResultUploadUrl(labOrderId),
      body: {'contentType': mimeType},
    );

    final url = '${issued['url'] ?? ''}';
    final key = '${issued['key'] ?? ''}';
    if (url.isEmpty || key.isEmpty) {
      throw UnknownException('The server did not issue an upload location');
    }

    await _uploader.putBytes(
      url: url,
      file: file,
      mime: mimeType,
      size: size,
      onProgress: onProgress,
    );

    // Filing is what completes the order, so it comes after the bytes land.
    await _api.postMap(
      ApiConstants.postLabOrdersResult(labOrderId),
      body: {
        's3Key': key,
        'title': fileName,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
  }

  @override
  Future<void> selectTestingCentre({
    required String labOrderId,
    required String testingCentreId,
  }) async {
    await _api.patch(
      ApiConstants.updateLabOrdersFacility(labOrderId),
      body: {'testingCentreId': testingCentreId},
    );
  }

  @override
  Future<void> respondToLabOrder({
    required String labOrderId,
    required bool accept,
  }) async {
    await _api.post(
      ApiConstants.postLabOrdersRespond(labOrderId),
      body: {'accept': accept},
    );
  }

  static List<String> _strings(dynamic v) =>
      v is List ? v.map(Api.str).where((s) => s.isNotEmpty).toList() : const [];
}
