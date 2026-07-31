import 'package:bienify_app/app.dart';
import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/data/static/pharmacy_shop_data.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/domain/entities/pharmacy_shop.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/presentation/bindings/shop_bindings.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/presentation/controllers/shop_medicines_controller.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/presentation/controllers/shop_orders_controller.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/presentation/controllers/shop_shell_controller.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/presentation/screens/medicine_form_screen.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/presentation/screens/shop_edit_profile_screen.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/presentation/screens/shop_notifications_screen.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/presentation/screens/shop_order_details_screen.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/presentation/screens/shop_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_fonts.dart';

/// Renders the pharmacy owner's section.
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

  testWidgets('Shop dashboard', (tester) async {
    await pump(tester, const ShopShellScreen(), binding: ShopShellBinding());

    expect(find.text('Aid Plus+'), findsOneWidget);
    expect(find.text(r'$160'), findsOneWidget);
    expect(find.text('Out of Stock'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(ShopShellScreen),
      matchesGoldenFile('shop_home.png'),
    );

    // The dashboard is taller than the frame; the alerts sit at its foot.
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -520),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(ShopShellScreen),
      matchesGoldenFile('shop_home_scrolled.png'),
    );
  });

  testWidgets('Orders tab, one state per chip', (tester) async {
    await pump(tester, const ShopShellScreen(), binding: ShopShellBinding());
    Get.find<ShopShellController>().select(ShopTab.orders);
    await tester.pumpAndSettle();

    final controller = Get.find<ShopOrdersController>();
    // Three orders in each of the six states, so every chip lands on a real
    // list rather than a single line.
    expect(controller.orders.length, ShopOrderStatus.values.length * 3);
    expect(controller.visible.length, 3);
    expect(
      controller.visible.every((o) => o.status == ShopOrderStatus.fresh),
      isTrue,
    );

    await settleImages(tester);
    await expectLater(
      find.byType(ShopShellScreen),
      matchesGoldenFile('shop_orders.png'),
    );

    controller.selectFilter(ShopOrderStatus.delivered);
    await tester.pump();
    expect(controller.visible.length, 3);
    expect(
      controller.visible.every((o) => o.status == ShopOrderStatus.delivered),
      isTrue,
    );
  });

  testWidgets('Order details, then accepting it', (tester) async {
    await pump(
      tester,
      const ShopOrderDetailsScreen(),
      binding: ShopOrdersBinding(),
    );
    final controller = Get.find<ShopOrdersController>();
    controller.selected.value = controller.orders.first;
    await tester.pumpAndSettle();

    expect(find.text('ORD-2841'), findsOneWidget);
    // The design prints $45.50 against lines that come to $66.50; the total
    // is summed from the lines rather than copied, so the arithmetic on
    // screen is right.
    expect(controller.selected.value!.total, 66.5);
    expect(find.text(r'$66.50'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(ShopOrderDetailsScreen),
      matchesGoldenFile('shop_order_details.png'),
    );

    // Accepting moves the row under the Accepted chip.
    controller.accept();
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(controller.orders.first.status, ShopOrderStatus.accepted);
  });

  testWidgets('Notifications', (tester) async {
    await pump(tester, const ShopNotificationsScreen());

    await settleImages(tester);
    await expectLater(
      find.byType(ShopNotificationsScreen),
      matchesGoldenFile('shop_notifications.png'),
    );
  });

  testWidgets('Medicines tab, its toggle and its search', (tester) async {
    await pump(tester, const ShopShellScreen(), binding: ShopShellBinding());
    Get.find<ShopShellController>().select(ShopTab.medicines);
    await tester.pumpAndSettle();

    final controller = Get.find<ShopMedicinesController>();
    expect(controller.visible.length, PharmacyShopData.medicines.length);

    await settleImages(tester);
    await expectLater(
      find.byType(ShopShellScreen),
      matchesGoldenFile('shop_medicines.png'),
    );

    // Taking a product off sale writes back into the list.
    final first = controller.medicines.first;
    controller.toggleListed(first, false);
    await tester.pump();
    expect(controller.medicines.first.isListed, isFalse);

    controller.query.value = 'aspirin';
    await tester.pump();
    expect(controller.visible.single.name, 'Aspirin 100mg');

    // Removing one takes it off the shelf.
    controller.query.value = '';
    controller.remove(first);
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(controller.medicines.length, PharmacyShopData.medicines.length - 1);
  });

  testWidgets('Add Medicine and Edit Medicine are one screen', (tester) async {
    await pump(
      tester,
      const MedicineFormScreen(),
      binding: ShopMedicinesBinding(),
    );
    final controller = Get.find<ShopMedicinesController>();

    expect(controller.editing.value, isNull);
    expect(find.text('Add Medicine'), findsWidgets);

    await settleImages(tester);
    await expectLater(
      find.byType(MedicineFormScreen),
      matchesGoldenFile('shop_add_medicine.png'),
    );

    // The same screen, titled by what it is doing.
    controller.editing.value = PharmacyShopData.medicines.first;
    await tester.pumpAndSettle();
    expect(find.text('Edit Medicine'), findsOneWidget);
    expect(find.text('Update Medicine'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(MedicineFormScreen),
      matchesGoldenFile('shop_edit_medicine.png'),
    );
  });

  testWidgets('Profile tab', (tester) async {
    await pump(tester, const ShopShellScreen(), binding: ShopShellBinding());
    Get.find<ShopShellController>().select(ShopTab.profile);
    await tester.pumpAndSettle();

    expect(find.text('Mohammod Jakuan'), findsOneWidget);
    expect(find.text('Payments and Credit'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(ShopShellScreen),
      matchesGoldenFile('shop_profile.png'),
    );
  });

  testWidgets('Edit Profile', (tester) async {
    await pump(
      tester,
      const ShopEditProfileScreen(),
      binding: ShopProfileBinding(),
      size: const Size(390, 1500),
    );

    await settleImages(tester);
    await expectLater(
      find.byType(ShopEditProfileScreen),
      matchesGoldenFile('shop_edit_profile.png'),
    );
  });
}
