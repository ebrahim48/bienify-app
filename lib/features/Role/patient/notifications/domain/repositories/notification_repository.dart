import '../entities/app_notification.dart';

/// The patient's notification feed.
abstract class NotificationRepository {
  /// Everything addressed to the signed-in user, newest first.
  Future<List<AppNotification>> list();

  /// Marks one notification read.
  Future<void> markRead(String id);

  /// Marks the whole feed read.
  Future<void> markAllRead();
}
