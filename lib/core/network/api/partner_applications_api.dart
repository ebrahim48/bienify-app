import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `partner-applications` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class PartnerApplicationsApi {
  PartnerApplicationsApi(this._c);

  final ApiClient _c;

  /// `POST /api/v1/partner-applications`
  Future<dynamic> createPartnerapplications({Object? body}) =>
      _c.post(ApiConstants.postPartnerApplications, body: body);

  /// `GET /api/v1/partner-applications/me`
  Future<dynamic> getMe({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.partnerApplicationsMe, query: query);
}
