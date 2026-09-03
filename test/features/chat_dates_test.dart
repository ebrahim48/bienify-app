import 'package:bienify_app/core/network/mappers.dart';
import 'package:bienify_app/features/Role/patient/chat/domain/entities/conversation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the timestamps a thread prints.
///
/// The reported symptom was a sent message showing a time that was not the
/// time it was sent, and no date anywhere to tell one day from another.
void main() {
  group('server timestamps', () {
    test('a UTC createdAt is read in the reader\'s own zone', () {
      // The server sends ISO-8601 with a `Z`. `DateTime.parse` hands that back
      // as UTC, and every label reads `.hour` straight off it — so before this
      // a message sent at 14:45 in Dhaka printed as 8:45 AM.
      final message = chatMessageFrom({
        '_id': 'm1',
        'body': 'hello',
        'createdAt': '2026-08-31T08:45:00.000Z',
        'senderId': 'doc-1',
      }, 'me');

      expect(message.sentAt.isUtc, isFalse);
      expect(
        message.sentAt,
        DateTime.utc(2026, 8, 31, 8, 45).toLocal(),
      );
      // The clock label follows, since it reads the local hour.
      expect(
        message.timeLabel,
        _expectedTimeLabel(DateTime.utc(2026, 8, 31, 8, 45).toLocal()),
      );
    });

    test('a string with no zone is left where it is', () {
      final message = chatMessageFrom({
        '_id': 'm2',
        'body': 'hello',
        'createdAt': '2026-08-31T08:45:00.000',
        'senderId': 'doc-1',
      }, 'me');

      expect(message.sentAt, DateTime(2026, 8, 31, 8, 45));
    });

    test('delivery and read receipts are converted too', () {
      // These drive "Seen" and the ticks; a receipt six hours in the past
      // reads as a message that was seen before it was sent.
      final message = chatMessageFrom({
        '_id': 'm3',
        'body': 'hello',
        'createdAt': '2026-08-31T08:45:00.000Z',
        'deliveredAt': '2026-08-31T08:46:00.000Z',
        'readAt': '2026-08-31T08:47:00.000Z',
        'senderId': 'me',
      }, 'me');

      expect(message.deliveredAt?.isUtc, isFalse);
      expect(message.readAt?.isUtc, isFalse);
    });
  });

  group('day labels', () {
    ChatMessage at(DateTime when) => ChatMessage(
      id: 'm-${when.millisecondsSinceEpoch}',
      text: 'x',
      sentAt: when,
      author: MessageAuthor.me,
    );

    test('names the calendar day the message was sent on', () {
      expect(at(DateTime(2026, 4, 1, 12, 37)).dayLabel, '1 Apr 2026');
      expect(at(DateTime(2026, 12, 25, 0, 5)).dayLabel, '25 Dec 2026');
    });

    test('two messages on one day are the same day', () {
      expect(
        at(DateTime(2026, 4, 1, 0, 1)).isSameDayAs(at(DateTime(2026, 4, 1, 23, 59))),
        isTrue,
      );
    });

    test('a minute past midnight is a different day', () {
      // The separator hangs off this: an off-by-one here either hides the
      // header on a new day or repeats it inside one.
      expect(
        at(DateTime(2026, 4, 1, 23, 59)).isSameDayAs(at(DateTime(2026, 4, 2, 0, 0))),
        isFalse,
      );
    });

    test('the same day-of-month in another month is not the same day', () {
      expect(
        at(DateTime(2026, 4, 1)).isSameDayAs(at(DateTime(2026, 5, 1))),
        isFalse,
      );
      expect(
        at(DateTime(2025, 4, 1)).isSameDayAs(at(DateTime(2026, 4, 1))),
        isFalse,
      );
    });
  });
}

String _expectedTimeLabel(DateTime local) {
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour12:$minute ${local.hour < 12 ? 'AM' : 'PM'}';
}
