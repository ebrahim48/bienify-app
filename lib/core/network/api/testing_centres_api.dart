import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `testing-centres` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class TestingCentresApi {
  TestingCentresApi(this._c);

  final ApiClient _c;

  /// `GET /api/v1/testing-centres`
  Future<dynamic> getTestingcentres({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.testingCentres, query: query);
}
