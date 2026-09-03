// Being told, rather than having to go and look.
//
// A doctor reviewing a result recorded a notification and said nothing to a
// patient sitting on the open app: the feed was read once when it opened and
// never again. Push covers the phone in a pocket and needs Firebase
// credentials this deployment does not have; this covers the phone in their
// hand.

import 'dart:async';

import 'package:bienify_app/core/exceptions/app_exceptions.dart';
import 'package:bienify_app/core/network/socket_service.dart';
import 'package:bienify_app/core/services/notification_inbox_service.dart';
import 'package:bienify_app/features/Role/patient/notifications/domain/entities/app_notification.dart';
import 'package:bienify_app/features/Role/patient/notifications/domain/repositories/notification_repository.dart';
import 'package:bienify_app/core/widgets/unread_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// A feed a test can publish onto, standing in for the socket.
/// A repository whose standing count a test can set.
class _FakeRepository implements NotificationRepository {
  _FakeRepository(this.count);

  int count;
  int reads = 0;
  bool throws = false;

  @override
  Future<int> unreadCount() async {
    reads += 1;
    if (throws) throw NoInternetException();
    return count;
  }

  @override
  Future<List<AppNotification>> list() async => const [];

  @override
  Future<void> markRead(String id) async {}

  @override
  Future<void> markAllRead() async {}
}

class _FakeFeed implements NotificationFeed {
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get notifications => _controller.stream;

  void publish(Map<String, dynamic> json) => _controller.add(json);

  Future<void> close() => _controller.close();
}

void main() {
  late _FakeFeed socket;
  late NotificationInboxService inbox;
  late List<String> announced;
  late _FakeRepository repository;

  Map<String, dynamic> reviewed({String id = 'n-1', String body = 'Bloods are normal.'}) => {
    '_id': id,
    'type': 'lab_result_ready',
    'title': 'Your doctor has reviewed your result',
    'body': body,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
  };

  setUp(() {
    Get.testMode = true;
    socket = _FakeFeed();
    announced = [];
    repository = _FakeRepository(0);
    inbox = NotificationInboxService(
      socket: socket,
      repository: repository,
      announce: (n) => announced.add(n.title),
    );
    inbox.onInit();
  });

  tearDown(() {
    inbox.onClose();
    unawaited(socket.close());
    Get.reset();
  });

  test('tells the patient the moment a review lands', () async {
    socket.publish(reviewed());
    await Future<void>.delayed(Duration.zero);

    expect(announced, ['Your doctor has reviewed your result']);
    expect(inbox.unread.value, 1);
    expect(inbox.arrivals.single.body, 'Bloods are normal.');
  });

  test('carries the doctor\'s own words, not a generic line', () async {
    socket.publish(
      reviewed(body: 'Referring you to cardiology.'),
    );
    await Future<void>.delayed(Duration.zero);

    expect(inbox.arrivals.single.body, 'Referring you to cardiology.');
    expect(inbox.arrivals.single.kind, NotificationKind.labResultReady);
  });

  test('does not list the same notification twice', () async {
    // A reconnect can replay, and two devices of one account both hear. A feed
    // that lists it twice reads as two separate results having been reviewed.
    socket.publish(reviewed());
    socket.publish(reviewed());
    await Future<void>.delayed(Duration.zero);

    expect(inbox.arrivals, hasLength(1));
    expect(inbox.unread.value, 1);
  });

  group('the badge on screen', () {
    testWidgets('prints the count, and moves when one arrives', (tester) async {
      Get.put<NotificationInboxService>(inbox);
      addTearDown(() => Get.delete<NotificationInboxService>(force: true));

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 876),
          builder: (context, _) => GetMaterialApp(
            home: Scaffold(
              body: Center(
                // The `.value` is read inside the `Obx`, not in a widget the
                // `Obx` builds — that arrangement watches nothing, and has
                // silently frozen a screen in this codebase twice.
                child: Obx(
                  () => UnreadBadge(
                    count: inbox.unread.value,
                    child: const Icon(Icons.notifications_none_rounded),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Nothing waiting draws nothing: a zero badge is a permanent mark saying
      // there is something to look at when there is not.
      expect(find.byKey(UnreadBadge.badgeKey), findsNothing);

      socket.publish(reviewed(id: 'x'));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);

      socket.publish(reviewed(id: 'y'));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);

      inbox.readAll();
      await tester.pumpAndSettle();
      expect(find.byKey(UnreadBadge.badgeKey), findsNothing);
    });

    test('stops counting exactly at ninety-nine', () {
      // Past this the exact number stops being useful and starts being wide.
      expect(UnreadBadge.label(1), '1');
      expect(UnreadBadge.label(99), '99');
      expect(UnreadBadge.label(100), '99+');
    });
  });

  group('the unread badge', () {
    test('seeds itself from the server on a cold open', () async {
      // Right before anything has arrived in this session — the count is not
      // "what turned up while I was watching".
      final seeded = NotificationInboxService(
        socket: socket,
        repository: _FakeRepository(7),
      );
      seeded.onInit();
      addTearDown(seeded.onClose);
      await Future<void>.delayed(Duration.zero);

      expect(seeded.unread.value, 7);
    });

    test('counts up as notifications arrive', () async {
      await Future<void>.delayed(Duration.zero);
      expect(inbox.unread.value, 0);

      socket.publish(reviewed(id: 'a'));
      socket.publish(reviewed(id: 'b'));
      await Future<void>.delayed(Duration.zero);

      expect(inbox.unread.value, 2);
    });

    test('comes down as they are read, and stops at zero', () {
      inbox.unread.value = 2;

      inbox.readOne();
      expect(inbox.unread.value, 1);
      inbox.readOne();
      expect(inbox.unread.value, 0);

      // A double tap, or a read racing a refresh, must not drive it negative:
      // a badge cannot show minus one waiting.
      inbox.readOne();
      expect(inbox.unread.value, 0);
    });

    test('clears when the whole feed is read', () async {
      socket.publish(reviewed());
      await Future<void>.delayed(Duration.zero);
      expect(inbox.unread.value, 1);

      inbox.readAll();

      expect(inbox.unread.value, 0);
      // Read is not gone: the row stays on the list.
      expect(inbox.arrivals, hasLength(1));
    });

    test('keeps the last count when the server cannot be reached', () async {
      await Future<void>.delayed(Duration.zero);
      socket.publish(reviewed());
      await Future<void>.delayed(Duration.zero);
      expect(inbox.unread.value, 1);

      repository.throws = true;
      await inbox.refresh();

      // Stale beats reset: zeroing it would say there is nothing to look at.
      expect(inbox.unread.value, 1);
    });
  });
}
