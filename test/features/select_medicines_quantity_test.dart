import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/routes/app_routes.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/data/static/medical_mock_data.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/data/static/pharmacy_mock_data.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/presentation/controllers/pharmacy_cart_controller.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/presentation/controllers/prescription_controller.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/presentation/screens/select_medicines_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_fonts.dart';

/// Covers the `− 1 +` control on Select Medicines.
///
/// It was wired to a literal `1` and two empty callbacks, so it looked like a
/// working stepper and neither number nor total ever moved.
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

  Future<PharmacyCartController> open(
    WidgetTester tester, {
    bool everythingStocked = true,
  }) async {
    final prescription = Get.put(PrescriptionController());
    prescription.matches.value = List.of(PharmacyMockData.matches);
    prescription.prescription.value = MedicalMockData.prescriptions().first;

    final cart = Get.put(PharmacyCartController())
      // The last match stocks only part of the script, which is how a row
      // without a stepper is produced.
      ..store.value = everythingStocked
          ? prescription.matches.first
          : prescription.matches.last;
    // Without the catalogue read every line is priced $0.00, and a total that
    // is zero however many packs you pick proves nothing.
    await cart.loadStoreCatalogue();

    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 876),
        builder: (_, _) => GetMaterialApp(
          theme: AppTheme.light,
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const SelectMedicinesScreen(),
          // Add to Cart navigates on; a stub is enough, what is asserted is
          // the basket it built before leaving.
          getPages: [
            GetPage(
              name: AppRoutes.pharmacyCart,
              page: () => const Scaffold(),
              transition: Transition.noTransition,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cart;
  }

  /// The first row's stepper controls. `at(0)` is that row's minus, `at(1)`
  /// its plus — the icons are unique to the stepper.
  Finder plus(int row) => find.byIcon(Icons.add_rounded).at(row);
  Finder minus(int row) => find.byIcon(Icons.remove_rounded).at(row);

  testWidgets('+ raises the number on the row', (tester) async {
    final cart = await open(tester);
    final medicine = cart.prescribed.first;

    expect(cart.quantityOf(medicine), 1);

    await tester.tap(plus(0));
    await tester.pump();

    expect(cart.quantityOf(medicine), 2);
    expect(find.text('2'), findsWidgets);
  });

  testWidgets('− lowers it again', (tester) async {
    final cart = await open(tester);
    final medicine = cart.prescribed.first;

    await tester.tap(plus(0));
    await tester.pump();
    await tester.tap(plus(0));
    await tester.pump();
    expect(cart.quantityOf(medicine), 3);

    await tester.tap(minus(0));
    await tester.pump();

    expect(cart.quantityOf(medicine), 2);
  });

  testWidgets('− stops at one', (tester) async {
    // The tick box is what removes a line here. A row left showing 0 while
    // still ticked would be counted by the total below it.
    final cart = await open(tester);
    final medicine = cart.prescribed.first;

    await tester.tap(minus(0));
    await tester.pump();
    await tester.tap(minus(0));
    await tester.pump();

    expect(cart.quantityOf(medicine), 1);
  });

  testWidgets('the total under the list follows the quantity', (tester) async {
    final cart = await open(tester);
    final medicine = cart.prescribed.first;
    cart.selectedIds
      ..clear()
      ..add(medicine.id);
    await tester.pump();

    final one = cart.selectionTotal;
    expect(one, greaterThan(0));

    await tester.tap(plus(0));
    await tester.pump();

    expect(cart.selectionTotal, one * 2);
    expect(find.text(cart.format(one * 2)), findsOneWidget);
  });

  testWidgets('Add to Cart carries the quantity into the basket', (
    tester,
  ) async {
    final cart = await open(tester);
    final medicine = cart.prescribed.first;
    cart.selectedIds
      ..clear()
      ..add(medicine.id);

    await tester.tap(plus(0));
    await tester.pump();
    await tester.tap(plus(0));
    await tester.pump();

    cart.addSelectionToCart();
    await tester.pumpAndSettle();

    // Three packs, not one line of one — the basket used to drop whatever the
    // stepper said.
    expect(cart.lines.single.quantity, 3);
    expect(cart.lines.single.total, medicine.price * 3);
  });

  testWidgets('stepping does not untick the row it sits in', (tester) async {
    // The whole card is a toggle, and the stepper sits inside it.
    final cart = await open(tester);
    final medicine = cart.prescribed.first;
    cart.selectedIds
      ..clear()
      ..add(medicine.id);
    await tester.pump();

    // One tap, not two: a plus followed by a minus would toggle the card
    // twice and land back on selected whatever the stepper absorbed.
    await tester.tap(plus(0));
    await tester.pump();

    expect(cart.isSelected(medicine), isTrue);
    expect(cart.quantityOf(medicine), 2);
  });

  testWidgets('an unavailable line has no stepper to press', (tester) async {
    final cart = await open(tester, everythingStocked: false);

    // Guard the fixture: with nothing out of stock this test would pass
    // whatever the screen did.
    expect(cart.availableCount, lessThan(cart.totalCount));

    // One stepper per available line, not one per prescribed line.
    expect(find.byIcon(Icons.add_rounded), findsNWidgets(cart.availableCount));
  });
}
