import 'package:bienify_app/app.dart';
import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/doctors/data/static/doctor_mock_data.dart';
import 'package:bienify_app/features/doctors/domain/entities/doctor_category.dart';
import 'package:bienify_app/features/doctors/presentation/bindings/doctors_bindings.dart';
import 'package:bienify_app/features/doctors/presentation/controllers/doctor_list_controller.dart';
import 'package:bienify_app/features/doctors/presentation/screens/doctor_list_screen.dart';
import 'package:bienify_app/features/doctors/presentation/widgets/doctor_filter_sheet.dart';
import 'package:bienify_app/features/main/presentation/bindings/main_binding.dart';
import 'package:bienify_app/features/main/presentation/controllers/main_nav_controller.dart';
import 'package:bienify_app/features/main/presentation/screens/main_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_fonts.dart';

/// Renders the Doctors journey: the tab, the category list, and the filter
/// sheet.
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
    Object? arguments,
    Size size = const Size(390, 1040),
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

  testWidgets('Find a doctor tab', (tester) async {
    await pump(tester, const MainShellScreen(), binding: MainBinding());
    Get.find<MainNavController>().select(2);
    await tester.pump();

    await settleImages(tester);
    await expectLater(
      find.byType(MainShellScreen),
      matchesGoldenFile('find_a_doctor.png'),
    );
  });

  testWidgets('General Doctor lists', (tester) async {
    await pump(
      tester,
      const DoctorListScreen(),
      binding: DoctorListBinding(),
      arguments: DoctorMockData.generalCategory,
      size: const Size(390, 876),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(DoctorListScreen),
      matchesGoldenFile('doctor_list.png'),
    );
  });

  testWidgets('filter sheet applies price and rating', (tester) async {
    await pump(
      tester,
      const DoctorListScreen(),
      binding: DoctorListBinding(),
      arguments: DoctorMockData.generalCategory,
      size: const Size(390, 876),
    );

    final controller = Get.find<DoctorListController>();
    final unfiltered = controller.doctors.length;

    await tester.tap(find.byType(InkResponse).last);
    await tester.pumpAndSettle();

    expect(find.byType(DoctorFilterSheet), findsOneWidget);
    await settleImages(tester);
    // Captured over the whole screen so the sheet's height and the scrim are
    // visible, not just the sheet's own bounds.
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('doctor_filter_sheet.png'),
    );

    // Every mock doctor rates 4.x, so a 5-star filter must empty the list —
    // a filter that changed nothing would prove nothing.
    expect(unfiltered, greaterThan(0));
    await tester.tap(find.text('5 Star'));
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(controller.filter.value.ratings, {5});
    expect(controller.doctors, isEmpty);
    expect(find.text('No doctors found'), findsOneWidget);

    // Reopening and resetting brings the full roster back.
    await tester.tap(find.byType(InkResponse).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(controller.doctors.length, unfiltered);
  });

  test('categories are distinct', () {
    final ids = DoctorMockData.categories.map((c) => c.id).toSet();
    expect(ids.length, DoctorMockData.categories.length);
    expect(DoctorMockData.generalCategory.name, 'General');
  });

  test('default filter is a no-op', () {
    expect(const DoctorFilter().isDefault, isTrue);
    expect(const DoctorFilter(ratings: {5}).isDefault, isFalse);
  });
}
