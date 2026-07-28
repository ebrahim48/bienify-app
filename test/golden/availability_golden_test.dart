import 'package:bienify_app/app.dart';
import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/doctors/data/static/doctor_mock_data.dart';
import 'package:bienify_app/features/doctors/presentation/bindings/doctors_bindings.dart';
import 'package:bienify_app/features/doctors/presentation/controllers/doctor_details_controller.dart';
import 'package:bienify_app/features/doctors/presentation/screens/doctor_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_fonts.dart';

/// Focused check on the Available Time slot chips.
///
/// Rendered at the real 390×876 viewport and scrolled into view, because
/// ScreenUtil's `.h` scales against screen height — capturing a tall
/// viewport stretches every vertical gap and misrepresents the design.
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

  Future<void> openDetails(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 876);
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
              page: () => const DoctorDetailsScreen(),
              binding: DoctorDetailsBinding(),
              transition: Transition.noTransition,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    Get.toNamed<void>('/target', arguments: DoctorMockData.doctors.first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    await tester.dragUntilVisible(
      find.text('Available Time'),
      find.byType(SingleChildScrollView).first,
      const Offset(0, -200),
    );
    await tester.pump();
  }

  testWidgets('slot chips: default, booked and selected states', (
    tester,
  ) async {
    await openDetails(tester);

    final controller = Get.find<DoctorDetailsController>();

    // Nothing is chosen until the patient taps, so Book Appointment cannot
    // fire with an empty slot.
    expect(controller.selectedSlot.value, isNull);
    expect(controller.canBook, isFalse);
    await settleImages(tester);
    await expectLater(
      find.byType(DoctorDetailsScreen),
      matchesGoldenFile('slots_unselected.png'),
    );

    // A booked slot stays unselectable.
    await tester.tap(find.text('11:00 AM'));
    await tester.pump();
    expect(controller.selectedSlot.value, isNull);

    // A free slot selects.
    await tester.tap(find.text('11:30 AM'));
    await tester.pump();
    expect(controller.selectedSlot.value?.label, '11:30 AM');
    expect(controller.canBook, isTrue);

    await settleImages(tester);
    await expectLater(
      find.byType(DoctorDetailsScreen),
      matchesGoldenFile('slots_selected.png'),
    );
  });
}
