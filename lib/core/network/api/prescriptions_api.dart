import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `prescriptions` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class PrescriptionsApi {
  PrescriptionsApi(this._c);

  final ApiClient _c;

  /// `GET /api/v1/prescriptions`
  Future<dynamic> getPrescriptions({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.prescriptions, query: query);

  /// `GET /api/v1/prescriptions/:id`
  Future<dynamic> getPrescriptions2({
    required String id,
    Map<String, dynamic>? query,
  }) => _c.get(ApiConstants.prescriptions2(id), query: query);
}
