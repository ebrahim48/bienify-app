import 'dart:io';

import 'package:bienify_app/app.dart';
import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/core/exceptions/app_exceptions.dart';
import 'package:bienify_app/core/routes/app_pages.dart';
import 'package:bienify_app/core/routes/app_routes.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/data/repositories/static_pharmacy_shop_repository.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/data/static/pharmacy_shop_data.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/domain/entities/pharmacy_shop.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/domain/repositories/pharmacy_shop_repository.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/presentation/bindings/shop_bindings.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/presentation/controllers/shop_medicines_controller.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/presentation/controllers/shop_orders_controller.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/presentation/controllers/shop_shell_controller.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/presentation/screens/medicine_form_screen.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/presentation/screens/shop_edit_profile_screen.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/presentation/screens/shop_notifications_screen.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/presentation/screens/shop_order_details_screen.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/presentation/screens/shop_orders_screen.dart';
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

    // All six states on one sideways row, not wrapped onto three lines.
    final chipRows = {
      for (final status in ShopOrderStatus.values)
        tester
            .getCenter(find.text(controller.statusLabel(status)).first)
            .dy
            .round(),
    };
    expect(chipRows, hasLength(1));

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

  testWidgets('Only a new order offers Accept and Decline', (tester) async {
    await pump(
      tester,
      const ShopOrderDetailsScreen(),
      binding: ShopOrdersBinding(),
    );
    final controller = Get.find<ShopOrdersController>();

    controller.selected.value = controller.orders.firstWhere(
      (o) => o.status == ShopOrderStatus.fresh,
    );
    await tester.pumpAndSettle();
    expect(find.text('Accept Order'), findsOneWidget);
    expect(find.text('Decline Order'), findsOneWidget);

    // The server refuses to move a delivered order — offering the buttons
    // on one is what produced "This order is delivered and cannot change
    // state further".
    controller.selected.value = controller.orders.firstWhere(
      (o) => o.status == ShopOrderStatus.delivered,
    );
    await tester.pumpAndSettle();
    expect(find.text('Accept Order'), findsNothing);
    expect(find.text('Decline Order'), findsNothing);
  });

  group('Orders read', () {
    late _CountingRepository repository;

    setUp(() {
      repository = _CountingRepository();
      Get.delete<PharmacyShopRepository>(force: true);
      Get.put<PharmacyShopRepository>(repository, permanent: true);
    });

    testWidgets('once per visit, across tabs and the detail route', (
      tester,
    ) async {
      // The app's own detail route, binding and all — without it the tap
      // below goes nowhere and cannot re-create the controller.
      Get.addPage(
        AppPages.routes.firstWhere((p) => p.name == AppRoutes.shopOrderDetails),
      );
      await pump(tester, const ShopShellScreen(), binding: ShopShellBinding());
      final shell = Get.find<ShopShellController>();
      shell.select(ShopTab.orders);
      await tester.pumpAndSettle();

      // Into a detail and back, then away to another tab and back.
      Get.find<ShopOrdersController>().openDetails(
        Get.find<ShopOrdersController>().orders.first,
      );
      await tester.pumpAndSettle();
      expect(find.byType(ShopOrderDetailsScreen), findsOneWidget);
      Get.back<void>();
      await tester.pumpAndSettle();
      shell.select(ShopTab.home);
      await tester.pumpAndSettle();
      shell.select(ShopTab.orders);
      await tester.pumpAndSettle();

      expect(repository.orderReads, 1);
    });

    testWidgets('again on a pull, and not twice for an overlapping pull', (
      tester,
    ) async {
      await pump(tester, const ShopShellScreen(), binding: ShopShellBinding());
      Get.find<ShopShellController>().select(ShopTab.orders);
      await tester.pumpAndSettle();
      expect(repository.orderReads, 1);

      await tester.fling(
        find
            .descendant(
              of: find.byType(ShopOrdersScreen),
              matching: find.byType(SingleChildScrollView),
            )
            .first,
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();
      expect(repository.orderReads, 2);

      final controller = Get.find<ShopOrdersController>();
      await Future.wait([controller.load(), controller.load()]);
      expect(repository.orderReads, 3);
    });

    testWidgets('a failed read says so, and is not an empty book', (
      tester,
    ) async {
      repository.fail = true;
      await pump(tester, const ShopShellScreen(), binding: ShopShellBinding());
      Get.find<ShopShellController>().select(ShopTab.orders);
      await tester.pumpAndSettle();

      expect(find.text('No orders under this chip yet'), findsNothing);
      expect(find.text('Server down'), findsOneWidget);

      repository.fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Server down'), findsNothing);
      expect(find.text('Sarah Johnson'), findsOneWidget);
    });
  });

  testWidgets('Notifications', (tester) async {
    await pump(
      tester,
      const ShopNotificationsScreen(),
      binding: ShopNotificationsBinding(),
    );

    await settleImages(tester);
    await expectLater(
      find.byType(ShopNotificationsScreen),
      matchesGoldenFile('shop_notifications.png'),
    );

    // The feed is pushed from the bell, so its chevron returns there.
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(ShopNotificationsScreen), findsNothing);
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

    // Taking a product off sale takes it off the shelf: the list the owner
    // sees is the listed stock, because `GET /medicines` filters on `isActive`
    // and no owner-scoped list includes the rest.
    final shelf = controller.medicines.length;
    final first = controller.medicines.first;
    await controller.toggleListed(first, false);
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(controller.medicines.map((m) => m.id), isNot(contains(first.id)));
    expect(controller.medicines.length, shelf - 1);

    controller.query.value = 'aspirin';
    await tester.pump();
    expect(controller.visible.single.name, 'Aspirin 100mg');

    // Removing one does the same thing by the other route.
    controller.query.value = '';
    final second = controller.medicines.first;
    await controller.remove(second);
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(controller.medicines.length, shelf - 2);
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

    // The same screen, titled by what it is doing — opened the way the pencil
    // opens it, so the fields are filled from the row rather than left blank.
    Get.addPage(
      AppPages.routes.firstWhere((p) => p.name == AppRoutes.shopMedicineForm),
    );
    controller.edit(PharmacyShopData.medicines.first);
    await tester.pumpAndSettle();
    expect(find.text('Paracetamol 500mg'), findsOneWidget);
    expect(find.text('31 Mar 2028'), findsOneWidget);
    expect(find.text('Edit Medicine'), findsOneWidget);
    expect(find.text('Update Medicine'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(MedicineFormScreen),
      matchesGoldenFile('shop_edit_medicine.png'),
    );
  });

  group('Medicine form', () {
    late _RecordingRepository repository;
    late ShopMedicinesController controller;

    setUp(() {
      repository = _RecordingRepository();
      Get.delete<PharmacyShopRepository>(force: true);
      Get.put<PharmacyShopRepository>(repository, permanent: true);
      // Pinned, so the calendar's range does not move with the day the suite
      // runs on. Registered before the route, whose binding then keeps it.
      controller = Get.put(
        ShopMedicinesController(now: () => DateTime(2026, 9, 29, 14)),
      );
    });

    // An app to hold the snackbars the save raises; the form itself is not
    // drawn, since a picked file here is not a real image.
    Future<void> pumpBlank(WidgetTester tester) =>
        pump(tester, const SizedBox.shrink());

    Future<void> fillRequired() async {
      controller.name.value = 'Zinc 50mg';
      controller.price.value = '4.00';
      controller.stock.value = '12';
    }

    testWidgets('the expiry is picked on a calendar and saved as a date', (
      tester,
    ) async {
      await pump(
        tester,
        const MedicineFormScreen(),
        binding: ShopMedicinesBinding(),
      );

      await tester.tap(find.text('Select a date'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);

      await tester.tap(find.text('30'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('30 Sep 2026'), findsOneWidget);

      await fillRequired();
      await controller.submit();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(repository.addedExpiry, DateTime(2026, 9, 30));
    });

    testWidgets('a medicine already past its expiry still opens the calendar', (
      tester,
    ) async {
      await pump(
        tester,
        const MedicineFormScreen(),
        binding: ShopMedicinesBinding(),
      );
      // Before today, so a calendar that started at today could not show it.
      controller.expiresOn.value = DateTime(2025, 9, 30);
      await tester.pumpAndSettle();

      await tester.tap(find.text('30 Sep 2025'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('an uploaded photo is saved with the medicine by its key', (
      tester,
    ) async {
      await pumpBlank(tester);
      await controller.attachImage(File('zinc.png'));
      expect(repository.uploadedMime, 'image/png');
      expect(controller.imageKey.value, 'key-1');

      await fillRequired();
      await controller.submit();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(repository.addedImageKey, 'key-1');
    });

    testWidgets('a photo that fails to upload is not left on the form', (
      tester,
    ) async {
      await pumpBlank(tester);
      repository.failUpload = true;
      await controller.attachImage(File('zinc.png'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(controller.pickedImage.value, isNull);
      expect(controller.imageKey.value, isNull);

      await fillRequired();
      await controller.submit();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(repository.addedImageKey, isNull);
    });

    testWidgets('an edit shows what the server kept, not what was sent', (
      tester,
    ) async {
      await pumpBlank(tester);
      await controller.load();
      final original = controller.medicines.first;
      controller.editing.value = original;
      await fillRequired();
      controller.expiresOn.value = DateTime(2030, 1, 31);
      repository.dropsExpiry = true;

      await controller.submit();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      final row = controller.medicines.firstWhere((m) => m.id == original.id);
      expect(row.expiresOn, isNull);
    });
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

/// The sample book, counting how often it is asked for.
class _CountingRepository extends StaticPharmacyShopRepository {
  int orderReads = 0;
  bool fail = false;

  @override
  Future<List<ShopOrder>> orders() {
    orderReads++;
    if (fail) throw NoInternetException('Server down');
    return super.orders();
  }
}

/// The sample shelf, recording what the form sends and able to refuse an
/// upload or drop a field the way a server that does not store it would.
class _RecordingRepository extends StaticPharmacyShopRepository {
  bool failUpload = false;
  bool dropsExpiry = false;
  DateTime? addedExpiry;
  String? addedImageKey;
  String? uploadedMime;

  @override
  Future<String> uploadMedicineImage({
    required String path,
    required String mimeType,
  }) async {
    uploadedMime = mimeType;
    if (failUpload) throw NoInternetException('Route not found');
    return 'key-1';
  }

  @override
  Future<ShopMedicine> addMedicine({
    required String name,
    required double price,
    required int stock,
    required bool isListed,
    String category = '',
    DateTime? expiresOn,
    String? imageKey,
  }) {
    addedExpiry = expiresOn;
    addedImageKey = imageKey;
    return super.addMedicine(
      name: name,
      price: price,
      stock: stock,
      isListed: isListed,
      category: category,
      expiresOn: expiresOn,
      imageKey: imageKey,
    );
  }

  @override
  Future<ShopMedicine> updateMedicine(
    ShopMedicine medicine, {
    String? imageKey,
  }) async => dropsExpiry
      ? ShopMedicine(
          id: medicine.id,
          name: medicine.name,
          category: medicine.category,
          stock: medicine.stock,
          price: medicine.price,
          isListed: medicine.isListed,
        )
      : medicine;
}
