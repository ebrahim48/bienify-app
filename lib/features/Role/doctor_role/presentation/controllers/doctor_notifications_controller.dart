import 'package:get/get.dart';

import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../patient/notifications/domain/entities/app_notification.dart';
import '../../../patient/notifications/domain/repositories/notification_repository.dart';
import '../../domain/entities/doctor_practice.dart';
import 'doctor_shell_controller.dart';

/// Backs the practitioner's notification feed, reached from the dashboard's
/// bell.
///
/// `GET /notifications` keys purely on the signed-in user, not on their
/// role, so this reuses the same [NotificationRepository] the patient feed
/// registers — one endpoint, one repository, two presentations, the same
/// pattern the message list already follows.
class DoctorNotificationsController extends GetxController {
  DoctorNotificationsController({NotificationRepository? repository})
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

  Future<void> open(AppNotification notification) async {
    if (!notification.isRead) {
      _applyRead(notification.id);
      try {
        await _repository.markRead(notification.id);
      } on AppException {
        // The tap already registered locally; the next load reconciles it.
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

  /// Where a notification of each kind leads, from the practitioner's side.
  ///
  /// Booking and payment events land the doctor on the tab that shows them
  /// live rather than a static receipt — the shell keeps its tabs in an
  /// `IndexedStack`, so this switches tabs the same way "See all" does,
  /// instead of pushing a route.
  void _navigateFor(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.appointmentBooked:
      case NotificationKind.appointmentConfirmed:
      case NotificationKind.appointmentCancelled:
      case NotificationKind.appointmentReminder:
        Get.find<DoctorShellController>().select(DoctorTab.appointments);
      case NotificationKind.labResultReady:
        Get.toNamed<void>(AppRoutes.doctorResultsToReview);
      case NotificationKind.payment:
        Get.toNamed<void>(AppRoutes.doctorEarnings);
      case NotificationKind.verificationUpdate:
        Get.toNamed<void>(AppRoutes.doctorEditProfile);
      case NotificationKind.prescriptionIssued:
      case NotificationKind.orderStatus:
      case NotificationKind.deliveryStatus:
      case NotificationKind.system:
      case NotificationKind.other:
        break;
    }
  }
}
