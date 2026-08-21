import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../static/notification_mock_data.dart';

/// The feed, served from sample content.
///
/// Read state is held here rather than regenerated per call, so marking a row
/// read survives a reload the way the real endpoint does.
class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository();

  List<AppNotification>? _rows;

  List<AppNotification> get _feed => _rows ??= NotificationMockData.feed();

  @override
  Future<List<AppNotification>> list() async => List.of(_feed);

  @override
  Future<void> markRead(String id) async {
    _rows = [
      for (final row in _feed)
        if (row.id == id) row.copyWith(isRead: true) else row,
    ];
  }

  @override
  Future<void> markAllRead() async {
    _rows = [for (final row in _feed) row.copyWith(isRead: true)];
  }
}
