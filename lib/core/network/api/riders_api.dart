import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `riders` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class RidersApi {
  RidersApi(this._c);

  final ApiClient _c;

  /// `GET /api/v1/riders/me`
  Future<dynamic> getMe({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.ridersMe, query: query);

  /// `POST /api/v1/riders/me`
  Future<dynamic> createMe({Object? body}) =>
      _c.post(ApiConstants.postRidersMe, body: body);

  /// `PATCH /api/v1/riders/me/availability`
  Future<dynamic> updateMeavailability({Object? body}) =>
      _c.patch(ApiConstants.updateRidersMeAvailability, body: body);

  /// `GET /api/v1/riders/me/deliveries`
  Future<dynamic> getMedeliveries({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.ridersMeDeliveries, query: query);

  /// `POST /api/v1/riders/me/documents`
  Future<dynamic> createMedocuments({Object? body}) =>
      _c.post(ApiConstants.postRidersMeDocuments, body: body);
}
