// Day headers in a thread.
//
// The expected labels are `dd/MM/yyyy` because the separator is drawn by the
// shared `ChatDaySeparator`, which says Today, Yesterday, the weekday within
// the week, and a numeric date beyond it. It replaced a screen-private widget
// that always printed `1 Apr 2026`; the behaviour these tests describe — one
// header per day, a new one when the day turns — is unchanged, only the words.

import 'package:bienify_app/features/Role/patient/chat/presentation/widgets/chat_day_separator.dart';
import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/models/chat_thread.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/Role/patient/chat/domain/entities/conversation.dart';
import 'package:bienify_app/features/Role/patient/chat/presentation/controllers/chat_controller.dart';
import 'package:bienify_app/features/Role/patient/chat/presentation/screens/chat_screen.dart';
import 'package:bienify_app/features/Role/patient/doctors/presentation/bindings/doctors_bindings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_fonts.dart';

/// Covers the date shown above a run of messages.
///
/// A bubble carries only `12:37 PM`, so before this a message from April and
/// one from today were indistinguishable in the thread.
void main() {
  setUpAll(loadAppFonts);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    await DependencyInjection.init(useMocks: true);
  });

  tearDown(() {
    DependencyInjection.clear();
    Get.reset();
  });

  ChatMessage message(String id, DateTime when) => ChatMessage(
    id: id,
    text: 'x',
    sentAt: when,
    author: MessageAuthor.me,
  );

  Future<ChatController> pumpChat(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 876);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 876),
        builder: (_, _) => GetMaterialApp(
          theme: AppTheme.light,
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => const Scaffold()),
            GetPage(
              name: '/chat',
              page: () => const ChatScreen(),
              binding: ChatBinding(),
              transition: Transition.noTransition,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    Get.toNamed<void>(
      '/chat',
      arguments: const ConversationPeer(
        id: 'user-1',
        thread: ChatThread.consultation('appt-1'),
        name: 'Dr Dana Okafor',
        specialty: 'Cardiology',
      ),
    );
    await tester.pump();
    await tester.pump();
    return Get.find<ChatController>();
  }

  testWidgets('heads the thread with the day its first message was sent', (
    tester,
  ) async {
    final controller = await pumpChat(tester);
    controller.messages.assignAll([
      message('m1', DateTime(2026, 4, 1, 12, 37)),
      message('m2', DateTime(2026, 4, 1, 12, 38)),
    ]);
    await tester.pump();

    // One header for the day, not one per message.
    expect(find.text('01/04/2026'), findsOneWidget);
  });

  testWidgets('starts a new header when the day changes', (tester) async {
    final controller = await pumpChat(tester);
    controller.messages.assignAll([
      message('m1', DateTime(2026, 4, 1, 23, 59)),
      message('m2', DateTime(2026, 4, 2, 0, 1)),
      message('m3', DateTime(2026, 4, 2, 9, 0)),
    ]);
    await tester.pump();

    expect(find.text('01/04/2026'), findsOneWidget);
    expect(find.text('02/04/2026'), findsOneWidget);
  });

  testWidgets('a message sent today is dated today, not the sample day', (
    tester,
  ) async {
    // The reported symptom: a message you just sent sat under timestamps
    // belonging to an unrelated day, with nothing on screen to say so.
    final controller = await pumpChat(tester);
    controller.messages.assignAll([
      message('old', DateTime(2026, 4, 1, 12, 37)),
      message('new', DateTime(2026, 8, 31, 14, 45)),
    ]);
    await tester.pump();

    // Two days, two headers. The newer label is deliberately not spelled out:
    // the separator says Today, Yesterday or a weekday for anything inside a
    // week, so hard-coding it here would make this test start failing on a
    // date that has nothing to do with the behaviour it describes.
    expect(find.text('01/04/2026'), findsOneWidget);
    expect(find.byType(ChatDaySeparator), findsNWidgets(2));
    // And the clock label on the new one is the local wall-clock time.
    expect(find.text('2:45 PM'), findsOneWidget);
  });
}
