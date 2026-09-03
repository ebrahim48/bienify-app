import 'dart:async';

import 'package:get/get.dart';

import '../../features/Role/patient/notifications/domain/entities/app_notification.dart';
import '../../features/Role/patient/notifications/domain/repositories/notification_repository.dart';
import '../exceptions/app_exceptions.dart';
import '../network/mappers.dart';
import '../network/socket_service.dart';

/// Tells the signed-in person about a notification the moment it happens.
///
/// The feed was pull-to-refresh only: a doctor could review a result, the
/// server would record the notification, and a patient sitting on the open app
/// would be told nothing at all until they happened to navigate to the list
/// and it refetched. Push covers the phone in a pocket and needs Firebase
/// credentials this deployment does not have; this covers the phone in their
/// hand and needs none. They are not substitutes for one another.
///
/// Registered permanently, like `CallService`, because a notification has to
/// arrive on whatever screen its recipient is already looking at — which is
/// exactly what a screen-scoped controller cannot do.
class NotificationInboxService extends GetxService {
  NotificationInboxService({
    required NotificationFeed socket,
    NotificationRepository? repository,
    void Function(AppNotification notification)? announce,
  }) : _socket = socket,
       _repository = repository,
       _announce = announce;

  final NotificationFeed _socket;

  /// Where the standing count comes from. Null where the graph has not
  /// registered one — the badge then counts only this session's arrivals,
  /// which is still better than counting nothing.
  final NotificationRepository? _repository;

  /// How an arrival is put in front of the person. Injectable so a test can
  /// read what was said without standing up a banner.
  final void Function(AppNotification notification)? _announce;

  /// Everything that has arrived on this connection, newest first.
  ///
  /// The feed reads this so a screen opened after the fact still shows what
  /// came in while it was closed, without waiting on a refetch.
  final RxList<AppNotification> arrivals = <AppNotification>[].obs;

  /// How many notifications are unread, as the badge prints it.
  ///
  /// Seeded from the server — which has always returned the count with the
  /// list — and then kept current in place: incremented when one arrives on
  /// the socket, decremented when one is read. Counting the page the feed
  /// happens to be holding is a different number as soon as there is more
  /// than one page of them, and re-reading the whole list on every change is
  /// a round trip to learn something the client already knows.
  final RxInt unread = 0.obs;

  /// Each arrival, for a screen that wants to fold it into its own list.
  Stream<AppNotification> get incoming => _incoming.stream;
  final _incoming = StreamController<AppNotification>.broadcast();

  StreamSubscription<Map<String, dynamic>>? _subscription;

  @override
  void onInit() {
    super.onInit();
    _subscription = _socket.notifications.listen(_onNotification);
    unawaited(refresh());
  }

  /// Reads the standing count from the server.
  ///
  /// Called at start-up and whenever the feed is re-read, so a badge is right
  /// on a cold open — not just after something has arrived in this session.
  /// Failures leave the current count alone: a badge that cannot be refreshed
  /// is better stale than reset to zero, which would read as "nothing to see".
  Future<void> refresh() async {
    final repository = _repository;
    if (repository == null) return;
    try {
      unread.value = await repository.unreadCount();
    } on AppException {
      // Deliberately silent; see above.
    }
  }

  @override
  void onClose() {
    unawaited(_subscription?.cancel());
    unawaited(_incoming.close());
    super.onClose();
  }

  void _onNotification(Map<String, dynamic> json) {
    final notification = appNotificationFrom(json);

    // The same row can arrive twice — a reconnect that replays, or two devices
    // of the same account — and a feed that lists it twice reads as two
    // separate results having been reviewed.
    if (arrivals.any((existing) => existing.id == notification.id)) return;

    arrivals.insert(0, notification);
    if (!notification.isRead) unread.value += 1;
    _incoming.add(notification);
    _announce?.call(notification);
  }

  /// One has been read. Never below zero: a double tap, or a read that races
  /// a refresh, must not drive the badge negative.
  void readOne() {
    if (unread.value > 0) unread.value -= 1;
  }

  /// The whole feed has been read.
  void readAll() => unread.value = 0;
}
