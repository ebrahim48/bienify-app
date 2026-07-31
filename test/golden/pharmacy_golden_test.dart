import 'package:bienify_app/app.dart';
import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/Role/patient/main/presentation/bindings/main_binding.dart';
import 'package:bienify_app/features/Role/patient/main/presentation/controllers/main_nav_controller.dart';
import 'package:bienify_app/features/Role/patient/main/presentation/screens/main_shell_screen.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/domain/entities/pharmacy.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/presentation/bindings/pharmacy_bindings.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/presentation/controllers/pharmacy_cart_controller.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/presentation/controllers/prescription_controller.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/presentation/screens/best_matches_screen.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/presentation/screens/delivery_feedback_screen.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/presentation/screens/order_status_screen.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/presentation/screens/pharmacy_cart_screen.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/presentation/screens/pharmacy_payment_screen.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/presentation/screens/select_medicines_screen.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/presentation/screens/upload_prescription_screen.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/presentation/widgets/location_dialog.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/presentation/widgets/medicine_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_fonts.dart';

/// Renders the Pharmacy journey.
///
/// Live tracking is left out: it hosts a `GoogleMap` platform view, which
/// cannot be created under `flutter_test`.
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
    Size size = const Size(390, 1150),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: BienifyApp.designSize,
        builder: (context, child) => GetMaterialApp(
          // The dialog goldens capture the whole `MaterialApp` so the blurred
          // page behind them is included; without this the checked-mode
          // ribbon would be baked into those images.
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

  /// Walks the flow far enough that the basket has the six prescribed lines.
  PharmacyCartController seedCart() {
    final prescription = Get.put(PrescriptionController());
    final cart = Get.put(PharmacyCartController())
      ..store.value = prescription.matches.first;
    cart
      ..toggleSelectAll()
      ..lines.value = [
        for (final medicine in cart.prescribed)
          if (cart.selectedIds.contains(medicine.id))
            CartLine(medicine: medicine),
      ];
    return cart;
  }

  testWidgets('Pharmacy tab', (tester) async {
    await pump(tester, const MainShellScreen(), binding: MainBinding());
    Get.find<MainNavController>().select(3);
    await tester.pump();

    await settleImages(tester);
    await expectLater(
      find.byType(MainShellScreen),
      matchesGoldenFile('pharmacy_tab.png'),
    );
  });

  testWidgets('Stores Near You survives a narrow device with large text', (
    tester,
  ) async {
    // The store row used to sit in a fixed-height horizontal `ListView`.
    // A height in `.h` around a `.w` avatar and two lines of `.sp` text
    // overflowed as soon as those scales diverged — reported as 1.6px on
    // `StoreAvatar`'s column. Scrolling the row into view is what exercises
    // it: `IndexedStack` lays the tab out but the row is below the fold.
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    // The height matters as much as the width: `.h` scales against the
    // viewport, so a tall test surface inflates the box and hides the bug.
    await pump(
      tester,
      const MainShellScreen(),
      binding: MainBinding(),
      size: const Size(320, 640),
    );
    Get.find<MainNavController>().select(3);
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byType(StoreAvatar).first,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Stores Near You strip', (tester) async {
    await pump(tester, const MainShellScreen(), binding: MainBinding());
    Get.find<MainNavController>().select(3);
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byType(StoreAvatar).first,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await settleImages(tester);
    await expectLater(
      find.byType(StoreAvatar).first,
      matchesGoldenFile('stores_near_you.png'),
    );
  });

  testWidgets('Upload prescription', (tester) async {
    await pump(
      tester,
      const UploadPrescriptionScreen(),
      binding: PrescriptionBinding(),
      size: const Size(390, 876),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(UploadPrescriptionScreen),
      matchesGoldenFile('upload_prescription.png'),
    );
  });

  testWidgets('Best matches', (tester) async {
    await pump(
      tester,
      const BestMatchesScreen(),
      binding: PrescriptionBinding(),
      size: const Size(390, 1000),
    );
    expect(find.text('3 pharmacies found'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(BestMatchesScreen),
      matchesGoldenFile('best_matches.png'),
    );
  });

  testWidgets('Select medicines marks the unavailable line', (tester) async {
    final prescription = Get.put(PrescriptionController());
    // The third match stocks four of six, so two lines are unavailable.
    final cart = Get.put(PharmacyCartController())
      ..store.value = prescription.matches.last;

    await pump(tester, const SelectMedicinesScreen(), size: const Size(390, 941));

    expect(cart.availableCount, 4);
    expect(find.text('Not Available'), findsNWidgets(2));

    await settleImages(tester);
    await expectLater(
      find.byType(SelectMedicinesScreen),
      matchesGoldenFile('select_medicines.png'),
    );
  });

  testWidgets('Cart totals respond to wallet and pickup', (tester) async {
    final cart = seedCart();
    await pump(tester, const PharmacyCartScreen(), size: const Size(390, 1150));

    final withDelivery = cart.total;
    cart.toggleWallet(true);
    await tester.pump();
    expect(cart.total, lessThan(withDelivery));

    cart.togglePickup(true);
    await tester.pump();
    expect(cart.deliveryFee, 0);

    await settleImages(tester);
    await expectLater(
      find.byType(PharmacyCartScreen),
      matchesGoldenFile('pharmacy_cart.png'),
    );
  });

  testWidgets('Payment shows Add before an address is saved', (tester) async {
    final cart = seedCart();
    await pump(
      tester,
      const PharmacyPaymentScreen(),
      size: const Size(390, 1000),
    );

    expect(cart.hasSavedAddress.value, isFalse);
    expect(find.text('Add'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(PharmacyPaymentScreen),
      matchesGoldenFile('pharmacy_payment.png'),
    );

    // Saving once flips the link to "Change".
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.byType(LocationDialog), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('location_dialog.png'),
    );

    await tester.tap(find.text('Add Location').last);
    await tester.pumpAndSettle();
    expect(cart.hasSavedAddress.value, isTrue);
    expect(find.text('Change'), findsOneWidget);
  });

  testWidgets('Order status', (tester) async {
    seedCart();
    await pump(
      tester,
      const OrderStatusScreen(),
      binding: OrderTrackingBinding(),
      size: const Size(390, 1050),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(OrderStatusScreen),
      matchesGoldenFile('order_status.png'),
    );
  });

  testWidgets('Delivery feedback', (tester) async {
    await pump(
      tester,
      const DeliveryFeedbackScreen(),
      size: const Size(390, 885),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(DeliveryFeedbackScreen),
      matchesGoldenFile('delivery_feedback.png'),
    );
  });
}
