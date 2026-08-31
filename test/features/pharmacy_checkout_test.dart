import 'package:bienify_app/features/Role/patient/profile/data/repositories/mock_account_repository.dart';
import 'package:bienify_app/core/exceptions/app_exceptions.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/routes/app_routes.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/domain/entities/pharmacy.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/domain/repositories/pharmacy_repository.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/presentation/controllers/pharmacy_cart_controller.dart';
import 'package:bienify_app/features/Role/patient/wallet/domain/repositories/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../support/test_fonts.dart';

/// Checkout against a server that only accepts real ObjectIds.
///
/// "Validation Failed" on Place Order has been reported twice. The first time
/// it was a placeholder *medicine* id; this covers the second cause, a
/// placeholder *pharmacy* id, which reached the user as an unhandled
/// exception that also jammed the button.
void main() {
  setUpAll(loadAppFonts);
  tearDown(Get.reset);

  // A real 24-character ObjectId, which is what the server's `objectId`
  // validator requires. Getting this wrong is exactly the bug under test.
  const realId = '65a000000000000000000001';

  Medicine medicine({String id = realId, String pharmacyId = realId}) =>
      Medicine(
        id: id,
        name: 'Paracetamol',
        dosage: '500mg',
        price: 4.5,
        pharmacyId: pharmacyId,
      );

  Future<PharmacyCartController> open(
    WidgetTester tester,
    _FakePharmacy pharmacy, {
    PharmacyStore? store,
    Medicine? line,
  }) async {
    final controller = PharmacyCartController(
      pharmacy: pharmacy,
      wallet: _FakeWallet(),
      account: MockAccountRepository(),
    );
    Get.put(controller);

    tester.view.physicalSize = const Size(390, 876);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 876),
        builder: (_, _) => GetMaterialApp(
          theme: AppTheme.light,
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(),
          // The success path navigates to order tracking. A stub is enough:
          // what is asserted is that the order reached the repository first.
          getPages: [
            GetPage(
              name: AppRoutes.pharmacyOrder,
              page: () => const Scaffold(),
              transition: Transition.noTransition,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    controller.store.value = store;
    controller.lines.add(CartLine(medicine: line ?? medicine()));
    // A real address, not just the flag. Setting `hasSavedAddress` alone used
    // to satisfy the checkout's guard with the address still blank, and the
    // order went out with ", " as its destination.
    await controller.saveAddress(
      const DeliveryAddress(line1: '14 Rua das Flores', city: 'Lisbon'),
    );
    return controller;
  }

  testWidgets('refuses a pharmacy the server could never accept', (
    tester,
  ) async {
    final pharmacy = _FakePharmacy();
    // A store from the static Best Matches list: its id is not an ObjectId,
    // and both `GET /medicines` and `POST /medicine-orders` require one.
    final controller = await open(
      tester,
      pharmacy,
      store: const PharmacyStore(
        id: 'store-1',
        name: 'City Pharmacy',
        address: '2 High Street',
        distanceLabel: '1.2 km',
        rating: 4.5,
        reviewCount: 20,
        etaLabel: '30 min',
        price: 12,
        availableCount: 1,
        totalCount: 1,
      ),
      line: medicine(pharmacyId: ''),
    );

    await controller.placeOrder();
    await settleSnackbar(tester);

    // Nothing is sent at all — the old code discovered this two requests in,
    // as a 400 from the medicine lookup.
    expect(pharmacy.searches, isEmpty);
    expect(pharmacy.placed, isEmpty);
    // And the button is released, rather than stuck behind a thrown future.
    expect(controller.isPlacingOrder.value, isFalse);
  });

  testWidgets('a failed lookup is reported, not thrown', (tester) async {
    // The lookup used to sit outside the try, so a rejection from the server
    // became an unhandled exception and left `isPlacingOrder` true for ever.
    final pharmacy = _FakePharmacy(failSearch: true);
    final controller = await open(
      tester,
      pharmacy,
      // A placeholder medicine id forces the name lookup.
      line: medicine(id: 'rx-1'),
    );

    await controller.placeOrder();
    await settleSnackbar(tester);

    expect(tester.takeException(), isNull);
    expect(controller.isPlacingOrder.value, isFalse);
    expect(pharmacy.placed, isEmpty);
  });

  testWidgets('will not place an order with nowhere to send it', (
    tester,
  ) async {
    final pharmacy = _FakePharmacy();
    final controller = await open(tester, pharmacy);

    // As if the patient had never saved one, and cleared the checkout's.
    await controller.saveAddress(const DeliveryAddress(line1: ''));
    await controller.placeOrder();
    await settleSnackbar(tester);

    // The guard used to test a "has one saved" flag rather than the address
    // itself, so an order went out addressed to ", ".
    expect(pharmacy.placed, isEmpty);
  });

  testWidgets('places the order when everything is real', (tester) async {
    final pharmacy = _FakePharmacy();
    final controller = await open(tester, pharmacy);

    await controller.placeOrder();
    await settleSnackbar(tester);

    expect(pharmacy.placed, hasLength(1));
    expect(pharmacy.placed.single.pharmacyId, realId);
    expect(pharmacy.placed.single.quantities, {realId: 1});
    expect(controller.isPlacingOrder.value, isFalse);
  });

  testWidgets('carries the pin when the address has one', (tester) async {
    // The server geocodes the typed address line when no pin is sent, which is
    // a guess and returns nothing at all without a Maps key — so most orders
    // reached the courier with no destination to draw a road to.
    final pharmacy = _FakePharmacy();
    final controller = await open(tester, pharmacy);

    await controller.saveAddress(
      const DeliveryAddress(
        line1: '12 Oak Street',
        city: 'Santo Domingo',
        lat: 18.4861,
        lng: -69.9312,
      ),
    );
    await controller.placeOrder();
    await settleSnackbar(tester);

    expect(pharmacy.placed.single.lat, 18.4861);
    expect(pharmacy.placed.single.lng, -69.9312);
  });

  testWidgets('sends no coordinates when the address was never pinned', (
    tester,
  ) async {
    final pharmacy = _FakePharmacy();
    final controller = await open(tester, pharmacy);

    await controller.saveAddress(
      const DeliveryAddress(line1: '12 Oak Street', city: 'Santo Domingo'),
    );
    await controller.placeOrder();
    await settleSnackbar(tester);

    // Null, not (0, 0) — which is a real place off the coast of Africa, and
    // would send a courier there rather than letting the server geocode.
    expect(pharmacy.placed.single.lat, isNull);
    expect(pharmacy.placed.single.lng, isNull);
  });
}

class _FakePharmacy implements PharmacyRepository {
  _FakePharmacy({this.failSearch = false});

  // Checkout neither reviews nor cancels; these exist so the fake still
  // satisfies the interface.
  @override
  Future<void> cancelOrder(String orderId) async {}

  @override
  Future<void> reviewPharmacy({
    required String orderId,
    required int rating,
  }) async {}

  @override
  Future<void> reviewRider({
    required String deliveryId,
    required int rating,
  }) async {}

  final bool failSearch;
  final List<String> searches = [];
  /// Named `placed`, not `orders`: the repository already has an `orders()`
  /// member and a field would collide with it.
  final List<
    ({
      String pharmacyId,
      Map<String, int> quantities,
      double? lat,
      double? lng,
    })
  >
  placed = [];

  @override
  Future<List<Medicine>> searchMedicines({
    String query = '',
    String? pharmacyId,
  }) async {
    searches.add(query);
    if (failSearch) throw ValidationException('Validation failed', const {});
    return [
      Medicine(
        id: '65a000000000000000000002',
        name: query,
        dosage: '500mg',
        price: 4.5,
        pharmacyId: pharmacyId ?? '',
      ),
    ];
  }

  @override
  Future<String> placeOrder({
    required String pharmacyId,
    required Map<String, int> quantitiesByMedicineId,
    required String deliveryAddress,
    String? prescriptionId,
    double? deliveryLat,
    double? deliveryLng,
  }) async {
    placed.add((
      pharmacyId: pharmacyId,
      quantities: quantitiesByMedicineId,
      lat: deliveryLat,
      lng: deliveryLng,
    ));
    return 'order-1';
  }

  @override
  Future<void> payOrder(String orderId) async {}

  @override
  Future<List<PharmacyStore>> stores({
    String query = '',
    String city = '',
  }) async => const [];

  @override
  Future<List<PharmacyOrder>> orders() async => const [];

  /// Checkout does not open the tracking map, so these are never reached here.
  @override
  Future<DeliveryRoute> deliveryRoute(String deliveryId) async =>
      const DeliveryRoute(status: 'unassigned');

  @override
  Future<Courier?> courierFor(String deliveryId) async => null;

  /// Checkout does not rank shops against a prescription.
  @override
  Future<List<PharmacyStore>> bestMatches(String prescriptionId) async =>
      const [];

  /// A known charge, so the checkout total under test is deterministic.
  @override
  Future<double> deliveryCharge() async => 2.50;

  @override
  Future<String?> deliveryIdForOrder(String orderId) async => null;
}

class _FakeWallet implements WalletRepository {
  @override
  Future<double> balance() async => 100;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
