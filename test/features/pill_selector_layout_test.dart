import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/core/widgets/app_pill_selector.dart';
import 'package:bienify_app/features/Role/patient/appointments/presentation/screens/appointments_screen.dart';
import 'package:bienify_app/features/Role/patient/main/presentation/bindings/main_binding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_fonts.dart';

/// Covers how a pill row lays out when its labels do not fit.
///
/// Appointment History's three labels are long enough that wrapping stacked
/// them one per line, which pushed the history itself off the first screen.
void main() {
  setUpAll(loadAppFonts);

  const labels = [
    'Upcoming Appointments',
    'Past Appointments',
    'Cancelled Appointment',
  ];

  Future<void> pump(
    WidgetTester tester, {
    required bool isScrollable,
  }) async {
    tester.view.physicalSize = const Size(390, 876);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 876),
        builder: (_, _) => MaterialApp(
          home: Scaffold(
            body: AppPillSelector(
              labels: labels,
              selectedIndex: 0,
              onSelected: (_) {},
              isLarge: true,
              isScrollable: isScrollable,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// The vertical extent the whole row occupies — one pill's height when the
  /// pills are on one line, three when they are stacked.
  double rowHeight(WidgetTester tester) =>
      tester.getSize(find.byType(AppPillSelector)).height;

  double pillTop(WidgetTester tester, String label) =>
      tester.getTopLeft(find.text(label)).dy;

  testWidgets('scrollable keeps every pill on one line', (tester) async {
    await pump(tester, isScrollable: true);

    // Same baseline for all three: they are beside each other, not stacked.
    expect(pillTop(tester, labels[1]), pillTop(tester, labels[0]));
    expect(pillTop(tester, labels[2]), pillTop(tester, labels[0]));
  });

  testWidgets('scrollable can be scrolled sideways to the last pill', (
    tester,
  ) async {
    await pump(tester, isScrollable: true);

    final before = tester.getTopLeft(find.text(labels[2])).dx;
    // Off the right edge to begin with — that is what the scroll is for.
    expect(before, greaterThan(390));

    await tester.drag(
      find.byType(AppPillSelector),
      const Offset(-400, 0),
    );
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text(labels[2])).dx, lessThan(before));
  });

  testWidgets('wrapping is still the default for every other chip row', (
    tester,
  ) async {
    await pump(tester, isScrollable: false);

    // Stacked: the later pills sit below the first, and the row is taller.
    expect(pillTop(tester, labels[2]), greaterThan(pillTop(tester, labels[0])));
  });

  testWidgets('the scrolling row is shorter than the wrapped one', (
    tester,
  ) async {
    await pump(tester, isScrollable: true);
    final scrollable = rowHeight(tester);

    await pump(tester, isScrollable: false);
    final wrapped = rowHeight(tester);

    // The whole point: one line instead of three.
    expect(scrollable, lessThan(wrapped));
  });

  testWidgets('Appointment History asks for the scrolling row', (tester) async {
    // The screen is where the choice is made; the widget only offers it.
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    await DependencyInjection.init(
      useMocks: true,
      clock: () => DateTime(2026, 9, 1, 9),
    );
    addTearDown(() {
      DependencyInjection.clear();
      Get.reset();
    });

    tester.view.physicalSize = const Size(390, 937);
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
            GetPage(
              name: '/',
              page: () => const AppointmentsScreen(),
              binding: MainBinding(clock: () => DateTime(2026, 9, 1, 9)),
            ),
          ],
        ),
      ),
    );
    // MainBinding builds every tab controller, and the mock feed answers on a
    // timer — left pending, it fails the test at teardown.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final selector = tester.widget<AppPillSelector>(
      find.byType(AppPillSelector),
    );
    expect(selector.isScrollable, isTrue);
  });
}
