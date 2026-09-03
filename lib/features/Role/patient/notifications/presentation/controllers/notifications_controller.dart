import 'dart:async';

import 'package:get/get.dart';

import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/services/notification_inbox_service.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// Backs the patient's notification feed, reached from the Home header's bell.
///
/// The bell used to switch to the Appointments tab, so a notification about an
/// order or a lab result led somewhere unrelated to it.
class NotificationsController extends GetxController {
  NotificationsController({
    NotificationRepository? repository,
    NotificationInboxService? inbox,
  }) : _repository = repository ?? Get.find<NotificationRepository>(),
       _inbox =
           inbox ??
           (Get.isRegistered<NotificationInboxService>()
               ? Get.find<NotificationInboxService>()
               : null);

  final NotificationRepository _repository;

  /// Live arrivals. Null only where the graph has not registered one — the
  /// list then behaves exactly as it did before, read on open.
  final NotificationInboxService? _inbox;

  StreamSubscription<AppNotification>? _arrivals;

  final RxList<AppNotification> notifications = <AppNotification>[].obs;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
    // Prepended as they arrive, so a notification that lands while the list is
    // open appears on it. The feed used to be read once on open and never
    // again, so a result reviewed a second later was simply not there.
    _arrivals = _inbox?.incoming.listen((notification) {
      if (notifications.any((existing) => existing.id == notification.id)) {
        return;
      }
      notifications.insert(0, notification);
    });
  }

  @override
  void onClose() {
    unawaited(_arrivals?.cancel());
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final rows = await _repository.list();
      // Anything that arrived on the socket but is not in the page the server
      // just returned — a notification written after the query ran.
      final known = rows.map((row) => row.id).toSet();
      final live = (_inbox?.arrivals ?? const <AppNotification>[])
          .where((arrival) => !known.contains(arrival.id))
          .toList();
      notifications.value = [...live, ...rows];
      // The list just came from the server; take its count of unread with it
      // rather than counting the page, which is a different number as soon as
      // there is more than one page.
      unawaited(_inbox?.refresh() ?? Future<void>.value());
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
      // The badge is shared with the header, so it has to come down with the
      // row rather than waiting for the feed to be re-read.
      _inbox?.readOne();
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
    _inbox?.readAll();
    try {
      await _repository.markAllRead();
    } on AppException catch (e) {
      // Nothing was written, so put the dots back rather than leaving the feed
      // claiming a state the server does not hold — and the badge with them.
      notifications.value = previous;
      unawaited(_inbox?.refresh() ?? Future<void>.value());
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
