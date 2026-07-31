import 'package:bienify_app/app.dart';
import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/Role/patient/cash_payment_process/presentation/bindings/cash_payment_bindings.dart';
import 'package:bienify_app/features/Role/patient/cash_payment_process/domain/entities/cash_payment.dart';
import 'package:bienify_app/features/Role/patient/cash_payment_process/presentation/controllers/cash_payment_controller.dart';
import 'package:bienify_app/features/Role/patient/cash_payment_process/presentation/controllers/payment_points_controller.dart';
import 'package:bienify_app/features/Role/patient/cash_payment_process/presentation/screens/how_to_pay_screen.dart';
import 'package:bienify_app/features/Role/patient/cash_payment_process/presentation/screens/nearby_payment_points_screen.dart';
import 'package:bienify_app/features/Role/patient/cash_payment_process/presentation/screens/payment_confirmed_screen.dart';
import 'package:bienify_app/features/Role/patient/cash_payment_process/presentation/screens/payment_pending_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_fonts.dart';

/// Renders the Cash Payment Process screens for comparison with the design.
///
/// The Map pane embeds a platform view that renders blank under
/// `flutter_test`, so the points screen is captured in its List state — the
/// pane whose layout is actually Flutter's to get right.
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
    Size size = const Size(390, 940),
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
    await tester.pump(const Duration(milliseconds: 200));
  }

  /// Releases the shared countdown before the framework's pending-timer check.
  void disposeCountdown() {
    if (Get.isRegistered<CashPaymentController>()) {
      Get.delete<CashPaymentController>(force: true);
    }
  }

  /// Registers the shared controller with a countdown pinned to 23:55:48.
  ///
  /// The production code expires 24h from `DateTime.now()`, so the rendered
  /// timer differs run to run and the golden can never match. Seeding
  /// `secondsRemaining` after `onInit` makes it byte-identical; the periodic
  /// tick never fires because the tests only pump 200ms.
  CashPaymentController putFrozenController() {
    final controller = Get.put(
      CashPaymentController(
        code: PaymentCode(
          code: '#BIE12345',
          amountLabel: '\$74.89',
          itemsLabel: '\$74.89 · 6 medicines',
          validFor: 24,
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        ),
      ),
    );
    controller.secondsRemaining.value = 23 * 3600 + 55 * 60 + 48;
    return controller;
  }

  testWidgets('How to Payment Works', (tester) async {
    putFrozenController();

    await pump(tester, const HowToPayScreen());
    await settleImages(tester);
    await expectLater(
      find.byType(HowToPayScreen),
      matchesGoldenFile('how_to_pay.png'),
    );
    disposeCountdown();
    await tester.pump();
  });

  testWidgets('Nearby Payment Points — list', (tester) async {
    // Registered up front and switched to List before the first build: the
    // Map pane hosts a `GoogleMap` platform view, which cannot be created
    // under `flutter_test`.
    putFrozenController();
    Get.put(PaymentPointsController()).showList();

    await pump(
      tester,
      const NearbyPaymentPointsScreen(),
      size: const Size(390, 880),
    );

    await settleImages(tester);
    await expectLater(
      find.byType(NearbyPaymentPointsScreen),
      matchesGoldenFile('payment_points_list.png'),
    );
    disposeCountdown();
    await tester.pump();
  });

  testWidgets('Payment Confirmed', (tester) async {
    await pump(
      tester,
      const PaymentConfirmedScreen(),
      binding: PaymentConfirmedBinding(),
      size: const Size(390, 1160),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(PaymentConfirmedScreen),
      matchesGoldenFile('payment_confirmed.png'),
    );
  });

  testWidgets('Payment Pending', (tester) async {
    putFrozenController();

    await pump(
      tester,
      const PaymentPendingScreen(),
      size: const Size(390, 900),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(PaymentPendingScreen),
      matchesGoldenFile('payment_pending.png'),
    );
    disposeCountdown();
    await tester.pump();
  });
}
