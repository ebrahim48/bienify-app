import 'package:get/get.dart';

import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// Backs the patient's notification feed, reached from the Home header's bell.
///
/// The bell used to switch to the Appointments tab, so a notification about an
/// order or a lab result led somewhere unrelated to it.
class NotificationsController extends GetxController {
  NotificationsController({NotificationRepository? repository})
    : _repository = repository ?? Get.find<NotificationRepository>();

  final NotificationRepository _repository;

  final RxList<AppNotification> notifications = <AppNotification>[].obs;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      notifications.value = await _repository.list();
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  int get unreadCount =>
      notifications.where((notification) => !notification.isRead).length;

  bool get hasUnread => unreadCount > 0;

  /// Marks [notification] read, then opens whatever it is about.
  ///
  /// The row is dimmed locally before the request lands — the read state is
  /// cosmetic, so making the patient wait on a round trip to see their own tap
  /// register would be worse than briefly being ahead of the server.
  Future<void> open(AppNotification notification) async {
    if (!notification.isRead) {
      _applyRead(notification.id);
      try {
        await _repository.markRead(notification.id);
      } on AppException {
        // Leave the row read: re-marking it unread would undo a tap the
        // patient just made, and the next load corrects it anyway.
      }
    }
    _navigateFor(notification.kind);
  }

  Future<void> markAllRead() async {
    if (!hasUnread) return;
    final previous = List.of(notifications);
    notifications.value = [
      for (final row in notifications) row.copyWith(isRead: true),
    ];
    try {
      await _repository.markAllRead();
    } on AppException catch (e) {
      // Nothing was written, so put the dots back rather than leaving the feed
      // claiming a state the server does not hold.
      notifications.value = previous;
      AppSnackbar.error(e.message);
    }
  }

  void _applyRead(String id) {
    notifications.value = [
      for (final row in notifications)
        if (row.id == id) row.copyWith(isRead: true) else row,
    ];
  }

  /// Where a notification of each kind leads.
  ///
  /// Kinds with no screen of their own stay on the feed rather than opening
  /// something loosely related — a wrong destination reads as a bug, a missing
  /// one reads as "nothing more to see".
  void _navigateFor(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.appointmentBooked:
      case NotificationKind.appointmentConfirmed:
      case NotificationKind.appointmentCancelled:
      case NotificationKind.appointmentReminder:
        Get.toNamed<void>(AppRoutes.pastAppointments);
      case NotificationKind.prescriptionIssued:
        Get.toNamed<void>(AppRoutes.allPrescriptions);
      case NotificationKind.labResultReady:
        Get.toNamed<void>(AppRoutes.testResults);
      case NotificationKind.orderStatus:
      case NotificationKind.deliveryStatus:
        Get.toNamed<void>(AppRoutes.orderHistory);
      case NotificationKind.payment:
        Get.toNamed<void>(AppRoutes.wallet);
      case NotificationKind.verificationUpdate:
      case NotificationKind.system:
      case NotificationKind.other:
        break;
    }
  }
}
