import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `diagnostic-tests` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class DiagnosticTestsApi {
  DiagnosticTestsApi(this._c);

  final ApiClient _c;

  /// `GET /api/v1/diagnostic-tests`
  Future<dynamic> getDiagnostictests({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.diagnosticTests, query: query);
}
