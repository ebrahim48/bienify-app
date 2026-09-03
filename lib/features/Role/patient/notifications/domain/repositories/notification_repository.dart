import '../entities/app_notification.dart';

/// The patient's notification feed.
abstract class NotificationRepository {
  /// Everything addressed to the signed-in user, newest first.
  Future<List<AppNotification>> list();

  /// How many are unread, across the whole feed rather than the page just
  /// listed.
  ///
  /// The server has always returned this alongside the rows; the app dropped
  /// it and counted the page it happened to be holding, which is a different
  /// number as soon as there are more notifications than one page.
  Future<int> unreadCount();

  /// Marks one notification read.
  Future<void> markRead(String id);

  /// Marks the whole feed read.
  Future<void> markAllRead();
}
