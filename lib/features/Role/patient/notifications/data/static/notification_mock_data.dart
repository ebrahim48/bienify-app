import '../../../../../../core/network/mappers.dart';
import '../../domain/entities/app_notification.dart';

/// Sample feed content, covering the kinds a patient actually sees so each
/// icon and the read/unread split are both exercised.
class NotificationMockData {
  NotificationMockData._();

  static List<AppNotification> feed() {
    final now = DateTime.now();

    AppNotification at({
      required String id,
      required NotificationKind kind,
      required String title,
      required String body,
      required Duration ago,
      bool isRead = false,
    }) {
      final createdAt = now.subtract(ago);
      return AppNotification(
        id: id,
        kind: kind,
        title: title,
        body: body,
        createdAt: createdAt,
        ageLabel: relativeAge(createdAt),
        isRead: isRead,
      );
    }

    return [
      at(
        id: 'n1',
        kind: NotificationKind.appointmentReminder,
        title: 'Appointment tomorrow',
        body:
            'Your video consultation with Dr. Kwame Mensah starts at 10:00 AM.',
        ago: const Duration(minutes: 12),
      ),
      at(
        id: 'n2',
        kind: NotificationKind.labResultReady,
        title: 'Lab results ready',
        body: 'Your Complete Blood Count results are available to view.',
        ago: const Duration(hours: 3),
      ),
      at(
        id: 'n3',
        kind: NotificationKind.prescriptionIssued,
        title: 'New prescription',
        body: 'Dr. Dana Okafor issued a prescription after your consultation.',
        ago: const Duration(hours: 9),
      ),
      at(
        id: 'n4',
        kind: NotificationKind.deliveryStatus,
        title: 'Order out for delivery',
        body: 'Your medicine order is on its way — arriving in 25–35 min.',
        ago: const Duration(days: 1),
        isRead: true,
      ),
      at(
        id: 'n5',
        kind: NotificationKind.payment,
        title: 'Payment received',
        body: 'We received \$45.00 for your consultation. Thank you.',
        ago: const Duration(days: 2),
        isRead: true,
      ),
      at(
        id: 'n6',
        kind: NotificationKind.appointmentConfirmed,
        title: 'Appointment confirmed',
        body: 'Dr. Linda Chen confirmed your appointment for Apr 3, 3:00 PM.',
        ago: const Duration(days: 4),
        isRead: true,
      ),
    ];
  }
}
