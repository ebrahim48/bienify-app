import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `lab-orders` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class LabOrdersApi {
  LabOrdersApi(this._c);

  final ApiClient _c;

  /// `GET /api/v1/lab-orders`
  Future<dynamic> getLaborders({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.labOrders, query: query);

  /// `POST /api/v1/lab-orders`
  Future<dynamic> createLaborders({Object? body}) =>
      _c.post(ApiConstants.postLabOrders, body: body);

  /// `POST /api/v1/lab-orders/:id/respond`
  Future<dynamic> createRespond({required String id, Object? body}) =>
      _c.post(ApiConstants.postLabOrdersRespond(id), body: body);

  /// `PATCH /api/v1/lab-orders/:id/review`
  Future<dynamic> updateReview({required String id, Object? body}) =>
      _c.patch(ApiConstants.updateLabOrdersReview(id), body: body);

  /// `PATCH /api/v1/lab-orders/:id/facility`
  Future<dynamic> updateFacility({required String id, Object? body}) =>
      _c.patch(ApiConstants.updateLabOrdersFacility(id), body: body);

  /// `POST /api/v1/lab-orders/:id/result/upload-url`
  Future<dynamic> createResultUploadUrl({required String id, Object? body}) =>
      _c.post(ApiConstants.postLabOrdersResultUploadUrl(id), body: body);

  /// `POST /api/v1/lab-orders/:id/result`
  Future<dynamic> createResult({required String id, Object? body}) =>
      _c.post(ApiConstants.postLabOrdersResult(id), body: body);

  /// `PATCH /api/v1/lab-orders/:id/status`
  Future<dynamic> updateStatus({required String id, Object? body}) =>
      _c.patch(ApiConstants.updateLabOrdersStatus(id), body: body);
}
