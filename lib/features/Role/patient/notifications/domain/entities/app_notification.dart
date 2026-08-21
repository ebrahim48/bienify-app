/// What a notification is about.
///
/// Mirrors the backend's `NOTIFICATION_TYPES`. [other] absorbs anything a
/// newer server sends that this build has not been taught yet — an unknown
/// type must still render as a row rather than crash the list.
enum NotificationKind {
  appointmentBooked,
  appointmentConfirmed,
  appointmentCancelled,
  appointmentReminder,
  prescriptionIssued,
  orderStatus,
  deliveryStatus,
  labResultReady,
  verificationUpdate,
  payment,
  system,
  other;

  /// Maps the server's snake_case `type` onto a case.
  static NotificationKind from(String value) => switch (value) {
    'appointment_booked' => appointmentBooked,
    'appointment_confirmed' => appointmentConfirmed,
    'appointment_cancelled' => appointmentCancelled,
    'appointment_reminder' => appointmentReminder,
    'prescription_issued' => prescriptionIssued,
    'order_status' => orderStatus,
    'delivery_status' => deliveryStatus,
    'lab_result_ready' => labResultReady,
    'verification_update' => verificationUpdate,
    'payment' => payment,
    'system' => system,
    _ => other,
  };
}

/// One row of the patient's notification feed.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.ageLabel,
    this.isRead = false,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime createdAt;

  /// `3 hours ago`, formatted where the row was built.
  final String ageLabel;

  /// The server marks this with `readAt`; the list dims a read row and drops
  /// its dot.
  final bool isRead;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    createdAt: createdAt,
    ageLabel: ageLabel,
    isRead: isRead ?? this.isRead,
  );
}
