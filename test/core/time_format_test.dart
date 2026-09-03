import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/network/mappers.dart';
import 'package:bienify_app/core/network/socket_service.dart';
import 'package:bienify_app/core/utils/time_format.dart';
import 'package:bienify_app/features/Role/patient/chat/domain/entities/conversation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Covers the timestamp bug: the server writes UTC, and every `.hour` read off
/// what `DateTime.parse` returned was therefore someone else's clock. An
/// optimistic bubble, built from `DateTime.now()`, showed the right time until
/// the stored row replaced it — at which point it jumped by the whole offset.
void main() {
  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');
  });

  tearDown(Get.reset);

  group('parsing what the server sent', () {
    test('turns a UTC instant into the device zone', () {
      final parsed = Api.date('2026-08-31T18:31:04.000Z');

      expect(parsed.isUtc, isFalse);
      expect(
        parsed,
        DateTime.utc(2026, 8, 31, 18, 31, 4).toLocal(),
      );
    });

    test('leaves a bubble agreeing with the clock it was sent on', () {
      // The sender's optimistic bubble is built from a local `DateTime.now()`;
      // the stored row comes back as UTC. Both must print the same face.
      final sentAt = DateTime(2026, 8, 31, 14, 5);
      final optimistic = ChatMessage(
        id: 'local',
        text: 'Hello',
        sentAt: sentAt,
        author: MessageAuthor.me,
      );
      final stored = ChatMessage(
        id: 'server',
        text: 'Hello',
        sentAt: Api.date(sentAt.toUtc().toIso8601String()),
        author: MessageAuthor.me,
      );

      expect(stored.timeLabel, optimistic.timeLabel);
      expect(stored.timeLabel, '2:05 PM');
    });

    test('reads a last-seen off the socket in the device zone', () {
      final state = PresenceState.fromJson({
        'userId': 'u1',
        'isOnline': false,
        'lastSeen': '2026-08-31T18:31:04.000Z',
      });

      // "last seen 18:31" printed off a UTC `DateTime` is the header claiming
      // an hour nobody was awake in.
      expect(state.lastSeen?.isUtc, isFalse);
      expect(state.lastSeen, DateTime.utc(2026, 8, 31, 18, 31, 4).toLocal());
    });
  });

  group('what a stamp says', () {
    final now = DateTime(2026, 8, 31, 20);

    test('prints the clock for today', () {
      expect(
        TimeFormat.threadStamp(DateTime(2026, 8, 31, 9, 7), now: now),
        '9:07 AM',
      );
    });

    test('says Yesterday rather than a time from another day', () {
      expect(
        TimeFormat.threadStamp(DateTime(2026, 8, 30, 9, 7), now: now),
        'Yesterday',
      );
    });

    test('names the weekday within the week', () {
      // 2026-08-27 is a Thursday.
      expect(
        TimeFormat.threadStamp(DateTime(2026, 8, 27, 9, 7), now: now),
        'Thursday',
      );
    });

    test('falls back to a date beyond a week', () {
      // A thread answered a fortnight ago used to read as `09:07`, which is
      // indistinguishable from one answered this morning.
      expect(
        TimeFormat.threadStamp(DateTime(2026, 8, 14, 9, 7), now: now),
        '14/08/2026',
      );
    });

    test('counts days by calendar date, not by elapsed hours', () {
      // 23:50 and 00:10 are twenty minutes apart and still different days.
      expect(
        TimeFormat.threadStamp(
          DateTime(2026, 8, 30, 23, 50),
          now: DateTime(2026, 8, 31, 0, 10),
        ),
        'Yesterday',
      );
    });

    test('prints midnight as 12 rather than 0', () {
      expect(TimeFormat.clock(DateTime(2026, 8, 31, 0, 4)), '12:04 AM');
      expect(TimeFormat.clock(DateTime(2026, 8, 31, 12, 4)), '12:04 PM');
    });
  });

  group('last seen', () {
    final now = DateTime(2026, 8, 31, 20);

    test('says today with the local time', () {
      expect(
        TimeFormat.lastSeen(DateTime(2026, 8, 31, 14, 32), now: now),
        'last seen today at 2:32 PM',
      );
    });

    test('says yesterday', () {
      expect(
        TimeFormat.lastSeen(DateTime(2026, 8, 30, 14, 32), now: now),
        'last seen yesterday at 2:32 PM',
      );
    });

    test('names the day beyond that', () {
      expect(
        TimeFormat.lastSeen(DateTime(2026, 8, 14, 14, 32), now: now),
        'last seen 14/08/2026 at 2:32 PM',
      );
    });
  });
}
