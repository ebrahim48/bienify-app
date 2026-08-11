import 'package:bienify_app/app.dart';
import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/Role/patient/appointments/data/static/appointment_mock_data.dart';
import 'package:bienify_app/features/Role/patient/appointments/domain/entities/appointment.dart';
import 'package:bienify_app/features/Role/patient/appointments/presentation/bindings/appointments_bindings.dart';
import 'package:bienify_app/features/Role/patient/appointments/presentation/controllers/appointments_controller.dart';
import 'package:bienify_app/features/Role/patient/appointments/presentation/controllers/video_call_controller.dart';
import 'package:bienify_app/features/Role/patient/appointments/presentation/screens/consultation_history_screen.dart';
import 'package:bienify_app/features/Role/patient/appointments/presentation/screens/video_call_screen.dart';
import 'package:bienify_app/features/Role/patient/appointments/presentation/widgets/cancel_reason_dialog.dart';
import 'package:bienify_app/features/Role/patient/appointments/presentation/widgets/review_dialog.dart';
import 'package:bienify_app/features/Role/patient/main/presentation/bindings/main_binding.dart';
import 'package:bienify_app/features/Role/patient/main/presentation/controllers/main_nav_controller.dart';
import 'package:bienify_app/features/Role/patient/main/presentation/screens/main_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_fonts.dart';

/// Renders the Appointments journey: the three history tabs, both blurred
/// dialogs, the call, and the consultation summary.
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

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    Bindings? binding,
    Object? arguments,
    Size size = const Size(390, 937),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: BienifyApp.designSize,
        builder: (context, child) => GetMaterialApp(
          theme: AppTheme.light,
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => const Scaffold()),
            GetPage(
              name: '/target',
              page: () => screen,
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

  /// "Today" for every render in this file.
  ///
  /// Without pinning it, the first card's date line comes from the wall clock
  /// and the golden stops matching at the next midnight.
  DateTime fixedNow() => DateTime(2026, 2, 20, 9);

  /// Opens the shell on the Appointments tab with its roster loaded.
  Future<AppointmentsController> openTab(WidgetTester tester) async {
    await pump(
      tester,
      const MainShellScreen(),
      binding: MainBinding(clock: fixedNow),
    );
    Get.find<MainNavController>().select(1);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    return Get.find<AppointmentsController>();
  }

  testWidgets('Upcoming tab groups by day and gates Join', (tester) async {
    final controller = await openTab(tester);

    // Today's visit is joinable; a February one is not.
    final upcoming = controller.groups
        .expand((group) => group.items)
        .toList();
    expect(upcoming.any(controller.isJoinable), isTrue);
    expect(upcoming.any((a) => !controller.isJoinable(a)), isTrue);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Join Visit'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(MainShellScreen),
      matchesGoldenFile('appointments_upcoming.png'),
    );
  });

  testWidgets('shell lays out on a narrow device with enlarged text', (
    tester,
  ) async {
    // Guards the whole shell, not just this tab: `IndexedStack` keeps every
    // tab laid out, so a narrow viewport with large text exercises Home's
    // cards too. This configuration caught a fixed-height overflow in the
    // "Need Care?" banner and a tag-row overflow on the Home feed.
    tester.platformDispatcher.textScaleFactorTestValue = 1.2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pump(
      tester,
      const MainShellScreen(),
      binding: MainBinding(clock: fixedNow),
      size: const Size(320, 900),
    );
    Get.find<MainNavController>().select(1);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });

  testWidgets('Past tab shows Book Again and Review', (tester) async {
    final controller = await openTab(tester);
    controller.selectTab(AppointmentTab.past);
    await tester.pump();

    expect(find.text('Book Again'), findsWidgets);
    expect(find.text('Review'), findsWidgets);

    await settleImages(tester);
    await expectLater(
      find.byType(MainShellScreen),
      matchesGoldenFile('appointments_past.png'),
    );
  });

  testWidgets('Cancelled tab shows Book Again only', (tester) async {
    final controller = await openTab(tester);
    controller.selectTab(AppointmentTab.cancelled);
    await tester.pump();

    expect(find.text('Book Again'), findsWidgets);
    expect(find.text('Review'), findsNothing);

    await settleImages(tester);
    await expectLater(
      find.byType(MainShellScreen),
      matchesGoldenFile('appointments_cancelled.png'),
    );
  });

  testWidgets('Cancel Reason dialog blurs the page and moves the booking', (
    tester,
  ) async {
    final controller = await openTab(tester);
    final before = controller.appointments
        .where((a) => a.status == AppointmentStatus.cancelled)
        .length;

    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel Booking'));
    await tester.pumpAndSettle();

    expect(find.byType(CancelReasonDialog), findsOneWidget);
    await settleImages(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('cancel_reason_dialog.png'),
    );

    await tester.tap(find.text('Cancel Now'));
    await tester.pumpAndSettle();

    expect(
      controller.appointments
          .where((a) => a.status == AppointmentStatus.cancelled)
          .length,
      before + 1,
    );
  });

  testWidgets('Review dialog blurs the page', (tester) async {
    final controller = await openTab(tester);
    controller.selectTab(AppointmentTab.past);
    await tester.pump();

    await tester.tap(find.text('Review').first);
    await tester.pumpAndSettle();

    expect(find.byType(ReviewDialog), findsOneWidget);
    await settleImages(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('review_dialog.png'),
    );
  });

  testWidgets('Video call', (tester) async {
    await pump(
      tester,
      const VideoCallScreen(),
      binding: VideoCallBinding(),
      arguments: AppointmentMockData.upcoming().first,
      size: const Size(390, 852),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(VideoCallScreen),
      matchesGoldenFile('video_call.png'),
    );

    // Releases the call timer before the pending-timer check.
    Get.delete<VideoCallController>(force: true);
    await tester.pump();
  });

  testWidgets('Consultation history', (tester) async {
    await pump(
      tester,
      const ConsultationHistoryScreen(),
      size: const Size(390, 876),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(ConsultationHistoryScreen),
      matchesGoldenFile('consultation_history.png'),
    );
  });
}
