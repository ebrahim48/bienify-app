import 'package:bienify_app/app.dart';
import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/doctor/domain/entities/doctor_practice.dart';
import 'package:bienify_app/features/doctor/presentation/bindings/doctor_bindings.dart';
import 'package:bienify_app/features/doctor/presentation/controllers/doctor_schedule_controller.dart';
import 'package:bienify_app/features/doctor/presentation/controllers/doctor_shell_controller.dart';
import 'package:bienify_app/features/doctor/presentation/screens/doctor_shell_screen.dart';
import 'package:bienify_app/features/doctor/presentation/screens/set_schedule_screen.dart';
import 'package:bienify_app/features/doctor/presentation/widgets/set_fees_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_fonts.dart';

/// Renders the practitioner section.
void main() {
  setUpAll(loadAppFonts);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    await DependencyInjection.init();
  });

  tearDown(() {
    DependencyInjection.clear();
    Get.reset();
  });

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    Bindings? binding,
    Size size = const Size(390, 876),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: BienifyApp.designSize,
        builder: (context, child) => GetMaterialApp(
          debugShowCheckedModeBanner: false,
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

    Get.toNamed<void>('/target');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  testWidgets('Doctor dashboard', (tester) async {
    // The true 390×876 frame, not a tall surface: `.h` scales against the
    // viewport height, so a 1500pt-tall test window inflates every fixed
    // height and the capture stops resembling the device.
    await pump(
      tester,
      const DoctorShellScreen(),
      binding: DoctorShellBinding(),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(DoctorShellScreen),
      matchesGoldenFile('doctor_home.png'),
    );

    // Scrolled, to reach the chart and today's list.
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -620),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(DoctorShellScreen),
      matchesGoldenFile('doctor_home_scrolled.png'),
    );
  });

  testWidgets('The other three tabs say they are not available yet', (
    tester,
  ) async {
    await pump(
      tester,
      const DoctorShellScreen(),
      binding: DoctorShellBinding(),
    );
    final shell = Get.find<DoctorShellController>();

    for (final tab in [
      DoctorTab.appointments,
      DoctorTab.message,
      DoctorTab.profile,
    ]) {
      shell.select(tab);
      await tester.pumpAndSettle();
      // One, not three: `IndexedStack` builds every child but marks the
      // unselected ones offstage, and `find.text` skips those.
      expect(find.text('Not available yet'), findsOneWidget);
    }

    await settleImages(tester);
    await expectLater(
      find.byType(DoctorShellScreen),
      matchesGoldenFile('doctor_not_available.png'),
    );
  });

  testWidgets('Set Schedule', (tester) async {
    // True device metrics, then scrolled — a tall surface would inflate every
    // `.h` and the controls would stop matching the design.
    await pump(
      tester,
      const SetScheduleScreen(),
      binding: DoctorScheduleBinding(),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(SetScheduleScreen),
      matchesGoldenFile('doctor_set_schedule.png'),
    );

    // Far enough to reach the weekly summary and Save.
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -2200),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(SetScheduleScreen),
      matchesGoldenFile('doctor_set_schedule_summary.png'),
    );
  });

  testWidgets('Closing a day drops it from the list and the summary', (
    tester,
  ) async {
    await pump(
      tester,
      const SetScheduleScreen(),
      binding: DoctorScheduleBinding(),
      size: const Size(390, 2000),
    );
    final controller = Get.find<DoctorScheduleController>();

    // The mock week opens five days; Friday and Saturday start closed.
    expect(controller.activeDays, 5);
    expect(controller.totalHoursLabel, '40h');

    controller.toggleDay(0, false);
    await tester.pump();
    expect(controller.activeDays, 4);
    expect(controller.days.first.slots, isEmpty);

    // Re-opening restores the default hours rather than leaving it unbookable.
    controller.toggleDay(0, true);
    await tester.pump();
    expect(controller.days.first.slots, isNotEmpty);
    expect(controller.activeDays, 5);
  });

  testWidgets('A slot needs both a start and an end', (tester) async {
    await pump(
      tester,
      const SetScheduleScreen(),
      binding: DoctorScheduleBinding(),
      size: const Size(390, 2000),
    );
    final controller = Get.find<DoctorScheduleController>();
    final before = controller.days.first.slots.length;

    controller.addSlot(0);
    await tester.pump();
    expect(controller.days.first.slots.length, before);

    // The refusal shows a snackbar, whose ticker must finish before the tree
    // is torn down.
    await tester.pumpAndSettle(const Duration(seconds: 5));

    controller
      ..setStart(0, '08:00 AM')
      ..setEnd(0, '09:00 AM')
      ..addSlot(0);
    await tester.pump();
    expect(controller.days.first.slots.length, before + 1);
    expect(controller.days.first.slots.last.label, '08:00 AM-09:00 AM');
  });

  testWidgets('Set Fees sheet', (tester) async {
    await pump(
      tester,
      const DoctorShellScreen(),
      binding: DoctorShellBinding(),
      size: const Size(390, 876),
    );

    await tester.tap(find.text('Set Fees'));
    await tester.pumpAndSettle();
    expect(find.byType(SetFeesSheet), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('doctor_set_fees.png'),
    );
  });
}
