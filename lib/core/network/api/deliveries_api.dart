import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `deliveries` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class DeliveriesApi {
  DeliveriesApi(this._c);

  final ApiClient _c;

  /// `POST /api/v1/deliveries`
  Future<dynamic> createDeliveries({Object? body}) =>
      _c.post(ApiConstants.postDeliveries, body: body);

  /// `GET /api/v1/deliveries/:id`
  Future<dynamic> getDeliveries({
    required String id,
    Map<String, dynamic>? query,
  }) => _c.get(ApiConstants.deliveries(id), query: query);

  /// `POST /api/v1/deliveries/:id/claim`
  Future<dynamic> createClaim({required String id, Object? body}) =>
      _c.post(ApiConstants.postDeliveriesClaim(id), body: body);

  /// `GET /api/v1/deliveries/:id/location`
  Future<dynamic> getLocation({
    required String id,
    Map<String, dynamic>? query,
  }) => _c.get(ApiConstants.deliveriesLocation(id), query: query);

  /// `PATCH /api/v1/deliveries/:id/location`
  Future<dynamic> updateLocation({required String id, Object? body}) =>
      _c.patch(ApiConstants.updateDeliveriesLocation(id), body: body);

  /// `PATCH /api/v1/deliveries/:id/status`
  Future<dynamic> updateStatus({required String id, Object? body}) =>
      _c.patch(ApiConstants.updateDeliveriesStatus(id), body: body);

  /// `GET /api/v1/deliveries/available`
  Future<dynamic> getAvailable({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.deliveriesAvailable, query: query);

  /// `GET /api/v1/deliveries/:id/messages`
  Future<dynamic> listMessages(String id, {Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.deliveriesMessages(id), query: query);

  /// `POST /api/v1/deliveries/:id/messages`
  Future<dynamic> createMessage(String id, {Object? body}) =>
      _c.post(ApiConstants.postDeliveriesMessages(id), body: body);

  /// `POST /api/v1/deliveries/:id/attachments/upload-url`
  Future<dynamic> createAttachmentUploadUrl(String id, {Object? body}) =>
      _c.post(ApiConstants.postDeliveriesAttachmentUploadUrl(id), body: body);
}
