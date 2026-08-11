import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `home` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class HomeApi {
  HomeApi(this._c);

  final ApiClient _c;

  /// `GET /api/v1/home/feed`
  Future<dynamic> getFeed({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.homeFeed, query: query);
}
