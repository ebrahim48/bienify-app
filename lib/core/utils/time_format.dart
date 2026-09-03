import 'package:get/get.dart';

import '../constants/app_strings.dart';

/// How the app prints an instant.
///
/// One place, because the same instant was being formatted three different
/// ways: a bubble printed a 12-hour clock, the thread list a 24-hour one, and
/// the header's "last seen" a third. Each read `.hour` off whatever `DateTime`
/// it was handed — which, for anything that came from the server, was a *UTC*
/// one. See `Api.date`, which now converts on the way in; these helpers assume
/// they are given a local instant and never convert again, so a value that has
/// somehow escaped that conversion shows up as an obviously wrong hour rather
/// than being silently patched here as well.
class TimeFormat {
  TimeFormat._();

  /// `2:32 PM`.
  static String clock(DateTime at) {
    final hour12 = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final minute = at.minute.toString().padLeft(2, '0');
    return '$hour12:$minute ${at.hour < 12 ? 'AM' : 'PM'}';
  }

  /// `31/08/2026`.
  static String numericDate(DateTime at) =>
      '${at.day.toString().padLeft(2, '0')}/'
      '${at.month.toString().padLeft(2, '0')}/${at.year}';

  /// The localised weekday, `Monday`..`Sunday`.
  static String weekday(DateTime at) =>
      AppStrings.weekdayNames[at.weekday - 1].tr;

  /// Whole days between two instants, counted by calendar date rather than by
  /// elapsed hours — 23:50 and 00:10 are one day apart, not zero.
  static int daysBetween(DateTime from, DateTime to) {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  static bool isToday(DateTime at, DateTime now) => daysBetween(at, now) == 0;

  static bool isYesterday(DateTime at, DateTime now) =>
      daysBetween(at, now) == 1;

  /// What a thread row prints on the right: the clock today, `Yesterday`
  /// yesterday, the weekday within the last week, and a date beyond that —
  /// the stamp every messaging app uses, and the reason a week-old thread no
  /// longer reads as though it were answered at 09:14 this morning.
  static String threadStamp(DateTime at, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final days = daysBetween(at, today);
    if (days <= 0) return clock(at);
    if (days == 1) return AppStrings.yesterday.tr;
    if (days < 7) return weekday(at);
    return numericDate(at);
  }

  /// The separator above the first message of a day: `Today`, `Yesterday`,
  /// the weekday, or the date.
  static String daySeparator(DateTime at, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final days = daysBetween(at, today);
    if (days <= 0) return AppStrings.today.tr;
    if (days == 1) return AppStrings.yesterday.tr;
    if (days < 7) return weekday(at);
    return numericDate(at);
  }

  /// `last seen today at 2:32 PM`, as a chat header prints it.
  static String lastSeen(DateTime at, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final time = clock(at);
    final days = daysBetween(at, today);
    if (days <= 0) return AppStrings.lastSeenToday.trParams({'time': time});
    if (days == 1) {
      return AppStrings.lastSeenYesterday.trParams({'time': time});
    }
    return AppStrings.lastSeenOn.trParams({
      'date': days < 7 ? weekday(at) : numericDate(at),
      'time': time,
    });
  }

  /// `00:42` / `1:02:07` — a running call timer.
  static String duration(Duration elapsed) {
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final minutes = elapsed.inMinutes % 60;
    if (elapsed.inHours > 0) {
      return '${elapsed.inHours}:${minutes.toString().padLeft(2, '0')}:$seconds';
    }
    return '${minutes.toString().padLeft(2, '0')}:$seconds';
  }
}
