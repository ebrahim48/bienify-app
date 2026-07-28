import 'package:bienify_app/app.dart';
import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/appointments/presentation/screens/appointments_screen.dart';
import 'package:bienify_app/features/home/data/static/home_mock_data.dart';
import 'package:bienify_app/features/doctors/presentation/widgets/doctor_list_card.dart';
import 'package:bienify_app/features/home/presentation/widgets/home_skeleton.dart';
import 'package:bienify_app/features/main/presentation/bindings/main_binding.dart';
import 'package:bienify_app/features/main/presentation/controllers/main_nav_controller.dart';
import 'package:bienify_app/features/main/presentation/screens/main_shell_screen.dart';
import 'package:bienify_app/features/main/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_fonts.dart';

/// Behaviour of the signed-in shell: the Home feed and the bottom navigation.
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

  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1400);
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
            GetPage(
              name: '/',
              page: () => const MainShellScreen(),
              binding: MainBinding(),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
  }

  /// Advances past the mock data source's simulated latency.
  Future<void> settleFeed(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  testWidgets('shows a skeleton first, then the feed', (tester) async {
    await pumpShell(tester);
    expect(find.byType(HomeSkeleton), findsOneWidget);

    await settleFeed(tester);

    expect(find.byType(HomeSkeleton), findsNothing);
    expect(find.text(HomeMockData.patientName), findsOneWidget);
    expect(find.text(HomeMockData.location), findsOneWidget);
  });

  testWidgets('renders every feed section from the design', (tester) async {
    await pumpShell(tester);
    await settleFeed(tester);

    // Lab request card.
    expect(find.text('Laboratory'), findsOneWidget);
    expect(find.text('Routine'), findsOneWidget);
    expect(find.text('Request sent'), findsOneWidget);
    expect(find.text('Review request'), findsOneWidget);
    expect(find.text('From Dr. Reed'), findsOneWidget);

    // Upcoming appointment.
    expect(find.text('Upcoming Appointments'), findsOneWidget);
    expect(find.text('Dr. Kwame Mensah'), findsOneWidget);
    expect(find.text('Apr 1, 2026 at 10:00 AM'), findsOneWidget);
    expect(find.text('Join'), findsOneWidget);

    // Nearby doctors.
    expect(find.text('Nearby Doctors'), findsOneWidget);
    expect(find.text('See all'), findsOneWidget);
    expect(
      find.byType(DoctorListCard),
      findsNWidgets(HomeMockData.doctors.length),
    );
    expect(find.text('Dr.Anjelica Peacock,MD'), findsOneWidget);
    expect(find.text('4.8 (220)'), findsOneWidget);
  });

  testWidgets('bottom navigation shows all four destinations', (tester) async {
    await pumpShell(tester);
    await settleFeed(tester);

    expect(find.byType(AppBottomNavBar), findsOneWidget);
    for (final label in ['Home', 'Appointments', 'Doctors', 'Pharmacy']) {
      expect(find.text(label), findsWidgets);
    }
  });

  testWidgets('tapping a destination switches tabs', (tester) async {
    await pumpShell(tester);
    await settleFeed(tester);

    await tester.tap(find.text('Appointments'));
    await tester.pump();

    expect(Get.find<MainNavController>().currentIndex.value, 1);
    // IndexedStack keeps every tab mounted; the shell just changes which one
    // is painted, so assert on the controller and the tab's presence.
    expect(find.byType(AppointmentsScreen), findsOneWidget);
  });

  testWidgets('feed unread count drives the Appointments badge', (
    tester,
  ) async {
    await pumpShell(tester);
    await settleFeed(tester);

    final nav = Get.find<MainNavController>();
    expect(
      nav.destinations[1].badgeCount,
      HomeMockData.feed.unreadAppointments,
    );
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('See all jumps to the Doctors tab', (tester) async {
    await pumpShell(tester);
    await settleFeed(tester);

    await tester.tap(find.text('See all'));
    await tester.pump();

    expect(Get.find<MainNavController>().currentIndex.value, 2);
  });
}
