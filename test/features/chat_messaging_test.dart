import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/network/mappers.dart';
import 'package:bienify_app/core/network/token_store.dart';
import 'package:bienify_app/core/theme/app_colors.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/core/utils/time_format.dart';
import 'package:bienify_app/core/widgets/presence_avatar.dart';
import 'package:bienify_app/features/Role/patient/chat/presentation/widgets/chat_day_separator.dart';
import 'package:bienify_app/features/Role/patient/chat/presentation/widgets/chat_header.dart';
import 'package:bienify_app/features/Role/patient/chat/domain/entities/conversation.dart';
import 'package:bienify_app/features/Role/patient/chat/presentation/screens/media_viewer_screen.dart';
import 'package:bienify_app/features/Role/patient/chat/presentation/widgets/chat_bubble.dart';
import 'package:bienify_app/features/Role/patient/chat/presentation/widgets/message_attachment_view.dart';
import 'package:bienify_app/features/Role/patient/chat/presentation/widgets/reaction_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Covers the three things messaging gained together: any emoji as a
/// reaction, a tappable attachment, and a connection dot in the thread list.
void main() {
  tearDown(Get.reset);

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 876),
        builder: (context, _) => GetMaterialApp(
          theme: AppTheme.light,
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pump();
  }

  /// The header sizes itself against the design canvas, so it needs the
  /// canvas. On the 800x600 default surface `72.h` collapses to 49px while the
  /// two lines of text do not scale with it, and the row overflows — a
  /// failure of the test's viewport, not of the widget.
  Future<void> pumpOnDesignCanvas(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390, 876);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester, child);
  }

  ChatMessage message({
    String id = 'm-1',
    String text = 'Hello',
    List<MessageReaction> reactions = const [],
    MessageKind kind = MessageKind.text,
    MessageAttachment? attachment,
    double? uploadProgress,
  }) => ChatMessage(
    id: id,
    text: text,
    sentAt: DateTime(2026, 2, 20, 9),
    author: MessageAuthor.me,
    reactions: reactions,
    kind: kind,
    attachment: attachment,
    uploadProgress: uploadProgress,
  );

  group('reactions', () {
    testWidgets('offers the full emoji keyboard behind the quick row', (
      tester,
    ) async {
      await pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => ReactionPicker.show(context),
            child: const Text('open'),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // The shortcuts are there…
      expect(find.text('❤️'), findsOneWidget);
      // …including the two the old five-name enum had no room for.
      expect(find.text('😢'), findsOneWidget);
      expect(find.text('😮'), findsOneWidget);

      // The row must fit: seven glyphs plus the toggle overflowed a 390pt
      // phone by 18px before it was made to scroll.
      expect(tester.takeException(), isNull);

      // …and the keyboard behind them is what makes the set open-ended
      // rather than merely longer. The toggle flipping is the observable
      // proof it opened.
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline_rounded), findsNothing);
    });

    testWidgets('returns a clear when the reader taps the one they had', (
      tester,
    ) async {
      String? chosen;
      await pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            // Already reacted with the heart.
            onPressed: () async =>
                chosen = await ReactionPicker.show(context, selected: '❤️'),
            child: const Text('open'),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('❤️'));
      await tester.pumpAndSettle();

      // Not the heart again: tapping your own reaction takes it back, and the
      // empty string is how that is told apart from a dismissed sheet.
      expect(chosen, ReactionPicker.clear);
    });

    testWidgets('groups repeats into one glyph with a count', (tester) async {
      await pump(
        tester,
        ChatBubble(
          message: message(
            reactions: const [
              MessageReaction(userId: 'u1', emoji: '😆'),
              MessageReaction(userId: 'u2', emoji: '😆'),
              MessageReaction(userId: 'u3', emoji: '🎉'),
            ],
          ),
        ),
      );

      expect(find.text('😆'), findsOneWidget);
      expect(find.text(' 2'), findsOneWidget);
      // An emoji no closed enum ever listed still draws.
      expect(find.text('🎉'), findsOneWidget);
    });

    test('maps a reaction stored under the old scheme to its glyph', () {
      // Rows written when reactions were names must not draw as the word
      // "love"; nothing was migrated, so reading has to do it.
      final legacy = messageReactionFrom({'kind': 'love', 'userId': 'u1'});
      expect(legacy?.emoji, '❤️');

      // And an emoji the server now stores passes straight through.
      final current = messageReactionFrom({'kind': '🎉', 'userId': 'u1'});
      expect(current?.emoji, '🎉');
    });
  });

  group('media viewer', () {
    testWidgets('an attachment opens it and a caption does not', (
      tester,
    ) async {
      var opened = 0;
      await pump(
        tester,
        ChatBubble(
          message: message(
            text: 'Here is the scan',
            kind: MessageKind.image,
            attachment: const MessageAttachment(
              name: 'scan.jpg',
              mime: 'image/jpeg',
              size: 1024,
              url: 'https://example.test/scan.jpg',
            ),
          ),
          onOpenMedia: () => opened++,
        ),
      );

      await tester.tap(find.byType(AttachmentBody));
      await tester.pump();
      expect(opened, 1);

      // The caption is not a handle on the viewer: tapping the words should
      // leave you in the thread.
      await tester.tap(find.text('Here is the scan'));
      await tester.pump();
      expect(opened, 1);
    });

    testWidgets('an attachment still uploading is not tappable', (
      tester,
    ) async {
      var opened = 0;
      await pump(
        tester,
        ChatBubble(
          message: message(
            text: '',
            kind: MessageKind.image,
            uploadProgress: 0.4,
            attachment: const MessageAttachment(
              name: 'scan.jpg',
              mime: 'image/jpeg',
              size: 1024,
              url: '/tmp/scan.jpg',
            ),
          ),
          onOpenMedia: () => opened++,
        ),
      );

      await tester.tap(find.byType(AttachmentBody), warnIfMissed: false);
      await tester.pump();
      // There is no signed URL yet, so opening it would show a blank page.
      expect(opened, 0);
    });

    test('skips messages with nothing to show', () {
      expect(MediaItem.fromMessage(message()), isNull);
      expect(
        MediaItem.fromMessage(
          message(
            kind: MessageKind.image,
            attachment: const MessageAttachment(
              name: 'x.jpg',
              mime: 'image/jpeg',
              size: 1,
              // The server could not sign it.
              url: null,
            ),
          ),
        ),
        isNull,
      );
    });
  });

  group('presence', () {
    testWidgets('draws no dot until presence is known', (tester) async {
      await pump(
        tester,
        const PresenceAvatar(isOnline: null, name: 'Ada', size: 44),
      );

      // An unanswered question must not look like a confident "offline".
      expect(find.byKey(PresenceAvatar.dotKey), findsNothing);
    });

    testWidgets('colours the dot by connection state', (tester) async {
      for (final (isOnline, expected) in [
        (true, AppColors.onlineDot),
        (false, AppColors.gray400),
      ]) {
        await pump(
          tester,
          PresenceAvatar(isOnline: isOnline, name: 'Ada', size: 44),
        );

        final dot = tester.widget<Container>(
          find.byKey(PresenceAvatar.dotKey),
        );
        expect((dot.decoration! as BoxDecoration).color, expected);
      }
    });

    testWidgets('the thread header carries the same dot as the list', (
      tester,
    ) async {
      // The header used to state presence in words only, so a row and the
      // thread it opened disagreed about how to show one fact.
      await pumpOnDesignCanvas(
        tester,
        ChatHeader(
          peer: const ConversationPeer(
            id: 'p1',
            name: 'Dr Grace',
            specialty: 'Cardiology',
          ),
          onBack: () {},
          isOnline: true,
        ),
      );

      expect(find.byKey(PresenceAvatar.dotKey), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
    });

    testWidgets('the header prints last seen on the local clock', (
      tester,
    ) async {
      final seen = DateTime.now().subtract(const Duration(hours: 2));
      await pumpOnDesignCanvas(
        tester,
        ChatHeader(
          peer: const ConversationPeer(
            id: 'p1',
            name: 'Dr Grace',
            specialty: 'Cardiology',
          ),
          onBack: () {},
          isOnline: false,
          lastSeen: seen,
        ),
      );

      // Read straight off the `DateTime` the socket parsed — which is UTC —
      // this said an hour nobody was awake in.
      expect(
        find.text('last seen today at ${TimeFormat.clock(seen)}'),
        findsOneWidget,
      );
    });
  });

  group('day separators', () {
    testWidgets('names the day above the first bubble of it', (tester) async {
      await pump(
        tester,
        Column(
          children: [
            ChatDaySeparator(
              at: DateTime(2026, 8, 31, 15, 57),
              now: DateTime(2026, 9, 1, 16),
            ),
            ChatDaySeparator(
              at: DateTime(2026, 9, 1, 15, 46),
              now: DateTime(2026, 9, 1, 16),
            ),
          ],
        ),
      );

      // A bubble prints only a clock, so without the day a message at 3:57 PM
      // yesterday sits above one at 3:46 PM today and the thread reads as
      // sorted wrong. It was not; the day was missing from the picture.
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });
  });

  group('calling from a thread', () {
    testWidgets('offers a call button only where there is a room to call into', (
      tester,
    ) async {
      const peer = ConversationPeer(
        id: 'p1',
        name: 'Dr Grace',
        specialty: 'Cardiology',
      );

      await pumpOnDesignCanvas(
        tester,
        ChatHeader(peer: peer, onBack: () {}),
      );
      // A courier thread, or a doctor nobody has booked: a dialler here would
      // be a control that looks live and does nothing.
      expect(find.byKey(ChatHeader.callButtonKey), findsNothing);

      var called = false;
      await pumpOnDesignCanvas(
        tester,
        ChatHeader(
          peer: peer,
          onBack: () {},
          onVideoCall: () => called = true,
        ),
      );
      expect(find.byKey(ChatHeader.callButtonKey), findsOneWidget);

      await tester.tap(find.byKey(ChatHeader.callButtonKey));
      await tester.pump();
      expect(called, isTrue);
    });
  });

  group('token store', () {
    test('reads the signed-in user id out of the access token', () {
      // A real JWT shape: header.payload.signature, payload base64url with
      // its padding stripped, which is what tripped a naive decode.
      const token =
          'eyJhbGciOiJIUzI1NiJ9.'
          'eyJzdWIiOiI2NWEwMDAwMDAwMDAwMDAwMDAwMDAwMDEiLCJyb2xlIjoicGF0aWVudCJ9.'
          'signature';
      expect(
        MemoryTokenStore(access: token).userId,
        '65a000000000000000000001',
      );
    });

    test('is null rather than throwing on anything that is not a JWT', () {
      expect(MemoryTokenStore().userId, isNull);
      expect(MemoryTokenStore(access: 'not-a-jwt').userId, isNull);
      expect(MemoryTokenStore(access: 'a.b.c').userId, isNull);
    });
  });
}
