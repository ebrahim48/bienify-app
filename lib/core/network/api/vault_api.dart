import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `vault` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class VaultApi {
  VaultApi(this._c);

  final ApiClient _c;

  /// `GET /api/v1/vault/health-profile`
  Future<dynamic> getHealthprofile({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.vaultHealthProfile, query: query);

  /// `PUT /api/v1/vault/health-profile`
  Future<dynamic> replaceHealthprofile({Object? body}) =>
      _c.put(ApiConstants.putVaultHealthProfile, body: body);

  /// `GET /api/v1/vault/records`
  Future<dynamic> getRecords({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.vaultRecords, query: query);

  /// `POST /api/v1/vault/records`
  Future<dynamic> createRecords({Object? body}) =>
      _c.post(ApiConstants.postVaultRecords, body: body);

  /// `GET /api/v1/vault/records/:id`
  Future<dynamic> getRecords2({
    required String id,
    Map<String, dynamic>? query,
  }) => _c.get(ApiConstants.vaultRecords2(id), query: query);

  /// `POST /api/v1/vault/records/:id/share`
  Future<dynamic> createRecordsshare({required String id, Object? body}) =>
      _c.post(ApiConstants.postVaultRecordsShare(id), body: body);

  /// `DELETE /api/v1/vault/records/:id/share/:doctorUserId`
  Future<dynamic> removeRecordsshare({
    required String id,
    required String doctorUserId,
    Object? body,
  }) => _c.delete(
    ApiConstants.deleteVaultRecordsShareDoctoruserid(id, doctorUserId),
    body: body,
  );

  /// `GET /api/v1/vault/records/shared-with-me`
  Future<dynamic> getRecordssharedwithme({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.vaultRecordsSharedWithMe, query: query);

  /// `POST /api/v1/vault/records/upload-url`
  Future<dynamic> createRecordsuploadurl({Object? body}) =>
      _c.post(ApiConstants.postVaultRecordsUploadUrl, body: body);
}
