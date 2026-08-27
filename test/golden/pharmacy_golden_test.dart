import 'package:bienify_app/features/Role/patient/profile/domain/repositories/account_repository.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/data/static/medical_mock_data.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/data/static/pharmacy_mock_data.dart';
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
import 'package:bienify_app/features/Role/patient/pharmacy/presentation/controllers/pharmacy_controller.dart';
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
    // Matches come from `GET /pharmacies/best-matches` now, so they are not
    // present the instant the controller is built. Set explicitly so every
    // test below starts from the same basket.
    prescription.matches.value = List.of(PharmacyMockData.matches);
    // The basket is the patient's own script now, not a fixed list of six demo
    // medicines, and it is read rather than constructed — so it too has to be
    // in place before the cart looks at it.
    prescription.prescription.value = MedicalMockData.prescriptions().first;
    final cart = Get.put(PharmacyCartController())
      ..store.value = prescription.matches.first;
    // The script is priced from the shop's catalogue, so it has to be read
    // before the basket has any figures in it.
    cart.loadStoreCatalogue();
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

    // The chips name what is actually on the shelf. They used to be six fixed
    // strings out of the design ("ex 50", "emojil") over a live catalogue.
    final pharmacy = Get.find<PharmacyController>();
    expect(pharmacy.chips.first, 'All');
    expect(
      pharmacy.chips.skip(1),
      everyElement(
        predicate<String>(
          (chip) => pharmacy.commonMedicines.any((m) => m.name.startsWith(chip)),
          'names a medicine on the shelf',
        ),
      ),
    );

    await settleImages(tester);
    await expectLater(
      find.byType(MainShellScreen),
      matchesGoldenFile('pharmacy_tab.png'),
    );
  });

  testWidgets('Choosing a chip searches for it, rather than only tinting it', (
    tester,
  ) async {
    await pump(tester, const MainShellScreen(), binding: MainBinding());
    Get.find<MainNavController>().select(3);
    await tester.pump();

    final pharmacy = Get.find<PharmacyController>();
    final chip = pharmacy.chips[1];

    await pharmacy.selectChip(chip);
    await tester.pump();

    expect(pharmacy.selectedChip.value, chip);
    expect(pharmacy.query.value, chip, reason: 'the chip drives the search');

    // And back out again: All has to clear the query, or the shelf stays
    // narrowed with no way to widen it.
    await pharmacy.selectChip(pharmacy.chips.first);
    await tester.pump();
    expect(pharmacy.query.value, isEmpty);
  });

  testWidgets('Add puts the medicine in the basket the badge counts', (
    tester,
  ) async {
    await pump(tester, const MainShellScreen(), binding: MainBinding());
    Get.find<MainNavController>().select(3);
    await tester.pump();

    final pharmacy = Get.find<PharmacyController>();
    // An empty basket wore a "1": the badge was its own counter, seeded at 1
    // and only ever incremented, with nothing behind it.
    expect(pharmacy.cartCount, 0);

    final medicine = pharmacy.commonMedicines.first;
    pharmacy.addToCart(medicine);
    await settleSnackbar(tester);

    final cart = Get.find<PharmacyCartController>();
    expect(cart.lines.single.medicine.id, medicine.id);
    expect(pharmacy.cartCount, 1);

    // The same medicine again is one line of two, not two lines.
    pharmacy.addToCart(medicine);
    await settleSnackbar(tester);
    expect(cart.lines, hasLength(1));
    expect(pharmacy.cartCount, 2);
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
    // The matches are fetched, so they arrive a frame later.
    await tester.pumpAndSettle();
    expect(find.text('3 pharmacies found'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(BestMatchesScreen),
      matchesGoldenFile('best_matches.png'),
    );
  });

  testWidgets('Select medicines marks the unavailable line', (tester) async {
    final prescription = Get.put(PrescriptionController());
    // Matches are read from `GET /pharmacies/best-matches` now, so they are
    // not there the instant the controller is constructed. Set explicitly so
    // the fixture under test is deterministic.
    prescription.matches.value = List.of(PharmacyMockData.matches);
    prescription.prescription.value = MedicalMockData.prescriptions().first;
    // The third match stocks four of six, so two lines are unavailable.
    final cart = Get.put(PharmacyCartController())
      ..store.value = prescription.matches.last;
    // The script is priced from the shop's own catalogue; without the read
    // every line shows $0.00.
    await cart.loadStoreCatalogue();

    await pump(
      tester,
      const SelectMedicinesScreen(),
      size: const Size(390, 941),
    );

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

    // An empty street is refused rather than saved: the dialog used to accept
    // anything, because the street was a label and not a field at all.
    await tester.tap(find.text('Add Location').last);
    await tester.pumpAndSettle();
    expect(cart.hasSavedAddress.value, isFalse);
    expect(find.text('Enter a street and number'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Street and number'),
      '14 Rua das Flores',
    );
    await tester.enterText(find.widgetWithText(TextField, 'City'), 'Lisbon');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Location').last);
    await tester.pumpAndSettle();
    expect(cart.hasSavedAddress.value, isTrue);
    expect(cart.address.value.line1, '14 Rua das Flores');
    expect(find.text('Change'), findsOneWidget);
    // The address the patient typed is the one the screen prints back.
    expect(find.text('14 Rua das Flores'), findsOneWidget);
    expect(find.text('Lisbon'), findsOneWidget);

    // Left unticked, so this is where *this* parcel goes and nothing more —
    // the profile is untouched and the next order still starts from home.
    expect(await Get.find<AccountRepository>().savedAddress(), isNull);
  });

  testWidgets('A checkout address reaches the profile only when asked', (
    tester,
  ) async {
    final cart = seedCart();
    await pump(
      tester,
      const PharmacyPaymentScreen(),
      size: const Size(390, 1000),
    );

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Street and number'),
      '9 Praça do Comércio',
    );
    await tester.tap(find.text('Also save this to my profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Location').last);
    await tester.pumpAndSettle();

    final saved = await Get.find<AccountRepository>().savedAddress();
    expect(saved?.line1, '9 Praça do Comércio');
    expect(cart.profileAddress.value?.line1, '9 Praça do Comércio');
    // Not an override any more: this *is* the profile address now, so there
    // is nothing to revert to and no link offering it.
    expect(cart.isOverridingAddress, isFalse);
    expect(find.text('Use my profile address'), findsNothing);
  });

  testWidgets('A one-off delivery address can be undone', (tester) async {
    final cart = seedCart();
    // Already living somewhere, the way a returning patient does.
    await cart.saveAddress(
      const DeliveryAddress(line1: '14 Rua das Flores', city: 'Lisbon'),
      saveToProfile: true,
    );

    await pump(
      tester,
      const PharmacyPaymentScreen(),
      size: const Size(390, 1000),
    );

    // Send this one parcel to the office instead.
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    // By position, not by hint: the hint only renders while a field is empty,
    // and this one arrives already carrying the profile address.
    await tester.enterText(
      find
          .descendant(
            of: find.byType(LocationDialog),
            matching: find.byType(TextField),
          )
          .first,
      '4 Avenida da Liberdade',
    );
    // "Change Location" is the dialog's title; the confirm button reads
    // "Update Location" once there is an address to update.
    await tester.tap(find.text('Update Location'));
    await tester.pumpAndSettle();

    expect(cart.address.value.line1, '4 Avenida da Liberdade');
    expect(cart.isOverridingAddress, isTrue);
    // Home is untouched, and the way back is on screen.
    expect(cart.profileAddress.value?.line1, '14 Rua das Flores');
    expect(find.text('Use my profile address'), findsOneWidget);

    await tester.tap(find.text('Use my profile address'));
    await tester.pumpAndSettle();
    expect(cart.address.value.line1, '14 Rua das Flores');
    expect(cart.isOverridingAddress, isFalse);
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
