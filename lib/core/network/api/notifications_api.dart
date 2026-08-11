import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `notifications` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class NotificationsApi {
  NotificationsApi(this._c);

  final ApiClient _c;

  /// `GET /api/v1/notifications`
  Future<dynamic> getNotifications({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.notifications, query: query);

  /// `POST /api/v1/notifications/:id/read`
  Future<dynamic> createRead({required String id, Object? body}) =>
      _c.post(ApiConstants.postNotificationsRead(id), body: body);

  /// `POST /api/v1/notifications/read-all`
  Future<dynamic> createReadall({Object? body}) =>
      _c.post(ApiConstants.postNotificationsReadAll, body: body);

  /// `POST /api/v1/notifications/send`
  Future<dynamic> createSend({Object? body}) =>
      _c.post(ApiConstants.postNotificationsSend, body: body);
}
