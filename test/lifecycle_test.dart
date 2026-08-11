import 'package:bienify_app/app.dart';
import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/routes/app_pages.dart';
import 'package:bienify_app/core/routes/app_routes.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/core/utils/app_navigator.dart';
import 'package:bienify_app/features/Role/patient/appointments/presentation/widgets/review_dialog.dart';
import 'package:bienify_app/features/Role/patient/doctors/presentation/widgets/doctor_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_fonts.dart';

/// Guards the two disposal bugs that only appear when a route goes away.
///
/// Both were reported from a device and neither shows up in a golden: the
/// screen renders perfectly right up to the moment it is torn down.
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

  /// Boots the real route table, so bindings and their disposal behave as
  /// they do in the app.
  Future<void> bootApp(WidgetTester tester) async {
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
          initialRoute: AppRoutes.home,
          getPages: AppPages.routes,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('leaving Search does not use a disposed text controller', (
    tester,
  ) async {
    await bootApp(tester);

    Get.toNamed<void>(AppRoutes.search);
    await tester.pumpAndSettle();
    expect(find.byType(DoctorSearchField), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'cardio');
    await tester.pump();

    // The pop is what used to throw: GetX deletes the route's controller
    // while the outgoing route is still painting its transition, so a
    // controller-owned `TextEditingController` was already disposed by the
    // time the field rebuilt.
    Get.back<void>();
    await tester.pumpAndSettle();

    // The debounce fires during the pop, so the mock repository's simulated
    // latency is still in flight. Let it land: the controller is closed by
    // then, and `search()` must not write to its observables.
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });

  testWidgets('typing, leaving and returning to Search is repeatable', (
    tester,
  ) async {
    await bootApp(tester);

    for (var visit = 0; visit < 3; visit++) {
      Get.toNamed<void>(AppRoutes.search);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'visit $visit');
      await tester.pump(const Duration(milliseconds: 400));
      Get.back<void>();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('submitting a review clears the stack cleanly', (tester) async {
    await bootApp(tester);

    // The path that produced the reported `'_dependents.isEmpty'` assertion
    // on device: `ReviewDialog.show` resolves the moment `Navigator.pop` is
    // called, while the dialog route is still animating out, and the stack is
    // cleared inside that window.
    //
    // The assertion itself does not reproduce here — `fake_async` does not
    // reproduce the real frame timing it depends on — so treat this as a
    // guard that the flow still ends at Home without throwing, not as proof
    // that the assertion is gone.
    Get.toNamed<void>(AppRoutes.deliveryFeedback);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Write Order Feedback'));
    await tester.pumpAndSettle();
    expect(find.byType(ReviewDialog), findsOneWidget);

    await tester.tap(find.text('Submit Review'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(Get.currentRoute, AppRoutes.home);
  });

  testWidgets('AppNavigator.resetTo clears a focused stack cleanly', (
    tester,
  ) async {
    await bootApp(tester);

    Get.toNamed<void>(AppRoutes.search);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);

    AppNavigator.resetTo(AppRoutes.home);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(Get.currentRoute, AppRoutes.home);
  });
}
