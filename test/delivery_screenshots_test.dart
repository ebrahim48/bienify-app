import 'dart:io';
import 'dart:ui' as ui;

import 'package:bienify_app/app.dart';
import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/Role/doctor_role/domain/entities/doctor_practice.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/bindings/doctor_bindings.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/controllers/doctor_shell_controller.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/screens/doctor_shell_screen.dart';
import 'package:bienify_app/features/Role/patient/doctors/presentation/bindings/doctors_bindings.dart';
import 'package:bienify_app/features/Role/patient/chat/domain/entities/conversation.dart';
import 'package:bienify_app/features/Role/patient/chat/presentation/controllers/chat_controller.dart';
import 'package:bienify_app/features/Role/patient/chat/presentation/screens/chat_screen.dart';
import 'package:bienify_app/features/Role/patient/main/presentation/bindings/main_binding.dart';
import 'package:bienify_app/features/Role/patient/main/presentation/controllers/main_nav_controller.dart';
import 'package:bienify_app/features/Role/patient/main/presentation/screens/main_shell_screen.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/domain/entities/pharmacy_shop.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/presentation/bindings/shop_bindings.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/presentation/controllers/shop_shell_controller.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/presentation/screens/shop_shell_screen.dart';
import 'package:bienify_app/features/Role/rider_role/domain/entities/rider.dart';
import 'package:bienify_app/features/Role/rider_role/presentation/bindings/rider_bindings.dart';
import 'package:bienify_app/features/Role/rider_role/presentation/controllers/rider_shell_controller.dart';
import 'package:bienify_app/features/Role/rider_role/presentation/screens/rider_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_fonts.dart';

/// Produces the client-facing screenshots in `delivery/`.
///
/// Run with:
///
///     flutter test --update-goldens test/delivery_screenshots_test.dart
///
/// These are *real renders of the real screens*, not mockups: the same
/// widgets the device runs, with the app's own fonts and theme, driven
/// through the same bindings. What differs from a phone is the data — the
/// demo repositories are used so the images are stable and carry no real
/// patient details, which is what makes them safe to send outside the team.
///
/// Rendered at 3x so the PNGs are 1170x2628 — a phone-class resolution that
/// survives being dropped into a slide or a PDF.
///
/// The capture is done by hand rather than through `matchesGoldenFile`, which
/// rasterises the layer at a fixed pixel ratio of 1.0 no matter what the view
/// is set to: going through it produced 390x876 thumbnails. Painting the
/// repaint boundary directly is what actually honours the scale.
void main() {
  setUpAll(loadAppFonts);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    await DependencyInjection.init(useMocks: true, clock: _fixedNow);
  });

  tearDown(() {
    DependencyInjection.clear();
    Get.reset();
  });

  /// Pins "today" so a screenshot taken next month still reads the same.
  DateTime fixedNow() => _fixedNow();

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    Bindings? binding,
    Object? arguments,
  }) async {
    // 390x876 logical at 3x — the design canvas, at the pixel density of the
    // phones this is demonstrated on.
    tester.view.physicalSize = const Size(390 * _scale, 876 * _scale);
    tester.view.devicePixelRatio = _scale;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: BienifyApp.designSize,
        builder: (context, child) => GetMaterialApp(
          // No debug ribbon across the corner of a client deliverable.
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => const Scaffold()),
            GetPage(
              // Wrapped so there is a repaint boundary to rasterise: the
              // screens themselves are not guaranteed to be one.
              name: '/target',
              page: () => RepaintBoundary(key: _shotKey, child: screen),
              binding: binding,
              transition: Transition.noTransition,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    Get.toNamed<void>('/target', arguments: arguments);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  /// Renders [screen] and writes `delivery/<name>.png` at [_scale].
  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget screen, {
    Bindings? binding,
    Object? arguments,
    Future<void> Function()? after,
  }) async {
    await pump(tester, screen, binding: binding, arguments: arguments);
    if (after != null) await after();
    await settleImages(tester);

    final boundary =
        tester.renderObject(find.byKey(_shotKey)) as RenderRepaintBoundary;

    // `toImage` and `toByteData` need a real event loop, which the fake async
    // clock in `flutter_test` does not provide.
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: _scale);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    });

    final file = File('delivery/$name.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(bytes!);

    // A screenshot nobody looked at is worth nothing to a client; fail loudly
    // rather than shipping a folder of empty files.
    expect(file.lengthSync(), greaterThan(10 * 1024), reason: '$name is blank');
  }

  // ─── Patient ─────────────────────────────────────────────────────────────

  testWidgets('01 patient home', (tester) async {
    await shoot(
      tester,
      '01-patient-home',
      const MainShellScreen(),
      binding: MainBinding(clock: fixedNow),
    );
  });

  testWidgets('02 patient appointments', (tester) async {
    await shoot(
      tester,
      '02-patient-appointments',
      const MainShellScreen(),
      binding: MainBinding(clock: fixedNow),
      after: () async {
        Get.find<MainNavController>().select(1);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      },
    );
  });

  testWidgets('03 patient find a doctor', (tester) async {
    await shoot(
      tester,
      '03-patient-doctors',
      const MainShellScreen(),
      binding: MainBinding(clock: fixedNow),
      after: () async {
        Get.find<MainNavController>().select(2);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      },
    );
  });

  testWidgets('04 patient pharmacy', (tester) async {
    await shoot(
      tester,
      '04-patient-pharmacy',
      const MainShellScreen(),
      binding: MainBinding(clock: fixedNow),
      after: () async {
        Get.find<MainNavController>().select(3);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      },
    );
  });

  testWidgets('05 patient consultation chat', (tester) async {
    await shoot(
      tester,
      '05-patient-chat',
      const ChatScreen(),
      binding: ChatBinding(),
      arguments: const ConversationPeer(
        id: 'doctor-1',
        name: 'Dr Reed',
        specialty: 'Cardiology',
      ),

      after: () async {
        // The sample thread repeats one canned reply and shows none of the
        // messaging features, so it is replaced with a short exchange that
        // does: delivery and read receipts, a shared document, and the seen
        // marker.
        //
        // Deliberately no emoji reactions. They work on a device, but this
        // renderer has no emoji face it can rasterise — tried Segoe UI Emoji
        // and the glyphs still came out as tofu boxes — and a box where a
        // heart belongs reads to a client as a bug rather than as a missing
        // test font. Capture that one from the emulator instead.
        final controller = Get.find<ChatController>();
        final at = _fixedNow();
        DateTime clock(int m) => at.add(Duration(minutes: m));

        controller.messages.assignAll([
          ChatMessage(
            id: 'd1',
            text: 'Good morning. How has the chest tightness been since '
                'Tuesday?',
            sentAt: clock(0),
            author: MessageAuthor.peer,
          ),
          ChatMessage(
            id: 'p1',
            text: 'Much better in the mornings, still there after stairs.',
            sentAt: clock(2),
            author: MessageAuthor.me,
            deliveredAt: clock(2),
            readAt: clock(3),
          ),
          ChatMessage(
            id: 'd2',
            text: 'Thanks — here is the lab request for your bloods.',
            sentAt: clock(4),
            author: MessageAuthor.peer,
          ),
          ChatMessage(
            id: 'd3',
            text: '',
            sentAt: clock(4),
            author: MessageAuthor.peer,
            kind: MessageKind.file,
            attachment: const MessageAttachment(
              name: 'Lab-request-CBC.pdf',
              mime: 'application/pdf',
              size: 248 * 1024,
              url: 'https://example.test/lab-request.pdf',
            ),
          ),
          ChatMessage(
            id: 'p2',
            text: 'Got it, booking that for Thursday. Thank you!',
            sentAt: clock(6),
            author: MessageAuthor.me,
            deliveredAt: clock(6),
            readAt: clock(7),
          ),
        ]);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      },
    );
  });

  // ─── Doctor ──────────────────────────────────────────────────────────────

  testWidgets('06 doctor dashboard', (tester) async {
    await shoot(
      tester,
      '06-doctor-dashboard',
      const DoctorShellScreen(),
      binding: DoctorShellBinding(),
    );
  });

  testWidgets('07 doctor appointments', (tester) async {
    await shoot(
      tester,
      '07-doctor-appointments',
      const DoctorShellScreen(),
      binding: DoctorShellBinding(),
      after: () async {
        Get.find<DoctorShellController>().select(DoctorTab.appointments);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      },
    );
  });

  // ─── Pharmacy owner ──────────────────────────────────────────────────────

  testWidgets('08 pharmacy dashboard', (tester) async {
    await shoot(
      tester,
      '08-pharmacy-dashboard',
      const ShopShellScreen(),
      binding: ShopShellBinding(),
    );
  });

  testWidgets('09 pharmacy orders', (tester) async {
    await shoot(
      tester,
      '09-pharmacy-orders',
      const ShopShellScreen(),
      binding: ShopShellBinding(),
      after: () async {
        Get.find<ShopShellController>().select(ShopTab.orders);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      },
    );
  });

  // ─── Rider ───────────────────────────────────────────────────────────────

  testWidgets('10 rider dashboard', (tester) async {
    await shoot(
      tester,
      '10-rider-dashboard',
      const RiderShellScreen(),
      binding: RiderShellBinding(),
    );
  });

  testWidgets('11 rider deliveries', (tester) async {
    await shoot(
      tester,
      '11-rider-deliveries',
      const RiderShellScreen(),
      binding: RiderShellBinding(),
      after: () async {
        Get.find<RiderShellController>().select(RiderTab.orders);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      },
    );
  });
}

/// 3x — one logical pixel becomes three, giving 1170x2628 PNGs.
const double _scale = 3;

/// Identifies the repaint boundary wrapping whichever screen is being shot.
const Key _shotKey = ValueKey('delivery-shot');

DateTime _fixedNow() => DateTime(2026, 2, 20, 9);
