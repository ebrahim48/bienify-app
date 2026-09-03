import '../../../../../../core/constants/api_constants.dart';
import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/network/mappers.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// The patient's feed, served by the API.
class ApiNotificationRepository implements NotificationRepository {
  const ApiNotificationRepository(this._api);

  final ApiClient _api;

  static const int _pageSize = 100;

  @override
  Future<List<AppNotification>> list() async {
    final rows = await _api.getList(
      ApiConstants.notifications,
      query: {'limit': _pageSize},
    );
    // The endpoint already pages newest first.
    return rows.map(appNotificationFrom).toList();
  }

  @override
  Future<int> unreadCount() async {
    // `GET /notifications` answers with `{ items, total, unread, … }`, so the
    // count comes back with the rows and needs no endpoint of its own. One row
    // is asked for rather than none: the count is the point, not the page.
    final data = await _api.getMap(
      ApiConstants.notifications,
      query: {'limit': 1},
    );
    return Api.integer(data['unread']);
  }

  @override
  Future<void> markRead(String id) async {
    await _api.post(ApiConstants.postNotificationsRead(id));
  }

  @override
  Future<void> markAllRead() async {
    await _api.post(ApiConstants.postNotificationsReadAll);
  }
}
