import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `health` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class HealthApi {
  HealthApi(this._c);

  final ApiClient _c;

  /// `GET /health`
  Future<dynamic> getHealth({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.health, query: query);

  /// `GET /ready`
  Future<dynamic> getReady({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.ready, query: query);
}
