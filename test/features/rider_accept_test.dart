// Accepting jobs, and holding more than one at a time.
//
// A courier on a shift takes several parcels and works them in whatever order
// suits the route, so what is covered here is that a job the server has agreed
// to is immediately workable — not only after a reload — and that holding a
// second one does not disturb the first.
import 'package:bienify_app/features/Role/patient/pharmacy/domain/entities/pharmacy.dart';
import 'package:bienify_app/features/Role/rider_role/domain/entities/rider.dart';
import 'package:bienify_app/features/Role/rider_role/data/services/rider_location_reporter.dart';
import 'package:bienify_app/features/Role/rider_role/domain/repositories/rider_repository.dart';
import 'package:bienify_app/features/Role/rider_role/presentation/controllers/rider_orders_controller.dart';
import 'dart:async';

import 'package:bienify_app/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../support/test_fonts.dart';

/// Serves the two boards and records what was claimed.
class _FakeRiderRepository implements RiderRepository {
  _FakeRiderRepository(this._board);

  final List<DeliveryRequest> _board;

  final List<String> claimed = <String>[];
  final List<(String, String)> statuses = <(String, String)>[];

  @override
  Future<List<DeliveryRequest>> requests() async => _board;

  @override
  Future<void> claim(String deliveryId) async => claimed.add(deliveryId);

  @override
  Future<void> setStatus(String deliveryId, String status, {String? reason}) async =>
      statuses.add((deliveryId, status));

  @override
  Future<void> reportLocation(String id, double lat, double lng) async {}

  @override
  Future<DeliveryRoute> route(String deliveryId) async =>
      const DeliveryRoute(status: 'assigned');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Stands in for the GPS.
///
/// The real reporter reaches the device's location channel, which no test
/// binding answers — it hangs rather than failing, which is why this is
/// injected rather than tolerated. What it records is which delivery was being
/// reported on, which is the behaviour worth asserting.
class _SilentReporter extends RiderLocationReporter {
  _SilentReporter(super.repository);

  final List<String> started = <String>[];
  int stops = 0;

  @override
  Future<String?> start(String deliveryId) async {
    started.add(deliveryId);
    return null;
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> dispose() async {}
}

void main() {
  _routeSmoothingTests();

  DeliveryRequest fresh(String id) => DeliveryRequest(
    id: id,
    code: 'ORD-$id',
    fee: 4.5,
    pickupName: 'City Pharmacy',
    customerName: 'Ana Reyes',
    customerAddress: '5 Elm St',
    customerId: 'u-$id',
    customerPhotoUrl: 'https://example.test/$id.png',
    minutes: 0,
    distanceKm: 0,
    items: 'Aspirin × 1',
    tab: RequestTab.fresh,
    // What the job board serves: nobody holds it yet.
    status: 'unassigned',
  );

  late _FakeRiderRepository repository;
  late _SilentReporter reporter;

  setUp(() {
    repository = _FakeRiderRepository([fresh('d-1'), fresh('d-2')]);
    reporter = _SilentReporter(repository);
  });

  tearDown(Get.reset);

  Future<RiderOrdersController> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 876),
        // `track` and a finished delivery both navigate, so the controller is
        // exercised behind a real navigator rather than in isolation.
        builder: (context, _) => GetMaterialApp(
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => const Scaffold()),
            GetPage(
              name: AppRoutes.riderTracking,
              page: () => const Scaffold(),
              transition: Transition.noTransition,
            ),
            GetPage(
              name: AppRoutes.riderDelivered,
              page: () => const Scaffold(),
              transition: Transition.noTransition,
            ),
          ],
        ),
      ),
    );
    final controller = Get.put(
      RiderOrdersController(repository: repository, reporter: reporter),
    );
    await tester.pump();
    return controller;
  }

  testWidgets('an accepted job is ready to move, not stuck as unassigned', (
    tester,
  ) async {
    final controller = await open(tester);

    await controller.accept(controller.requests.first);
    await settleSnackbar(tester);

    final accepted = controller.requests.firstWhere((r) => r.id == 'd-1');
    expect(repository.claimed, ['d-1']);
    expect(accepted.tab, RequestTab.accepted);
    // The card kept the board's `unassigned`, and every downstream read went
    // wrong with it: the tracking sheet showed no progress, and its button
    // found no transition out of `unassigned` and refused the job as already
    // finished. A courier could accept work and then not move it.
    expect(accepted.status, 'assigned');
  });

  testWidgets('accepting does not blank the customer behind the parcel', (
    tester,
  ) async {
    final controller = await open(tester);

    await controller.accept(controller.requests.first);
    await settleSnackbar(tester);

    final accepted = controller.requests.firstWhere((r) => r.id == 'd-1');
    // `copyWith` dropped both, so accepting a job lost the account the chat
    // needs and the photo the tracking sheet draws.
    expect(accepted.customerId, 'u-d-1');
    expect(accepted.customerPhotoUrl, 'https://example.test/d-1.png');
  });

  testWidgets('two jobs can be held at once, each moving on its own', (
    tester,
  ) async {
    final controller = await open(tester);

    await controller.accept(controller.requests.firstWhere((r) => r.id == 'd-1'));
    await controller.accept(controller.requests.firstWhere((r) => r.id == 'd-2'));
    await settleSnackbar(tester);

    expect(repository.claimed, ['d-1', 'd-2']);
    expect(
      controller.requests.where((r) => r.tab == RequestTab.accepted).length,
      2,
    );

    // Advancing one leaves the other exactly where it was — the courier picks
    // up the second parcel later in the round, not because the first moved.
    controller.active.value = ActiveDelivery(
      request: controller.requests.firstWhere((r) => r.id == 'd-1'),
      status: 'assigned',
    );
    await controller.arrived();
    await settleSnackbar(tester);

    expect(repository.statuses, [('d-1', 'picked_up')]);
    expect(
      controller.requests.firstWhere((r) => r.id == 'd-1').status,
      'picked_up',
    );
    expect(
      controller.requests.firstWhere((r) => r.id == 'd-2').status,
      'assigned',
    );
  });

  testWidgets('reporting follows the parcel and stops when it is handed over', (
    tester,
  ) async {
    final controller = await open(tester);
    final job = fresh('d-1').copyWith(tab: RequestTab.accepted, status: 'in_transit');
    controller.requests.value = [job];

    controller.track(job);
    await settleSnackbar(tester);

    // Nothing reported the courier's position before this existed, so
    // `lastLocation` was never written and the customer's map had a route with
    // no courier on it.
    expect(reporter.started, ['d-1']);

    controller.active.value = ActiveDelivery(request: job, status: 'in_transit');
    // Not awaited: handing a parcel over opens the receipt, and `arrived`
    // waits for the courier to leave it. In a test nobody does, so awaiting it
    // here would hang rather than fail.
    unawaited(controller.arrived());
    await settleSnackbar(tester);

    // A delivered parcel is not moving, and the server rejects positions on
    // one.
    expect(repository.statuses.last, ('d-1', 'delivered'));
    expect(reporter.stops, greaterThan(0));
  });
}

/// A pushed position must move the courier and disturb nothing else.
///
/// Both tracking screens rebuilt `DeliveryRoute` by hand to apply a ping, so
/// every field the payload does not carry reverted to its default. The road
/// and the arrival time were wiped a few seconds after the map drew them.
void _routeSmoothingTests() {
  group('a pushed position', () {
    DeliveryRoute road() => const DeliveryRoute(
      status: 'in_transit',
      courier: MapPoint(lat: 23.78, lng: 90.41),
      pickup: MapPoint(lat: 23.81, lng: 90.41, label: 'City Pharmacy'),
      dropoff: MapPoint(lat: 23.75, lng: 90.39, label: '5 Elm St'),
      path: [MapPoint(lat: 23.78, lng: 90.41), MapPoint(lat: 23.75, lng: 90.39)],
      distanceMeters: 5217,
      etaSeconds: 987,
    );

    test('keeps the road and the arrival time', () {
      final moved = road().movedTo(const MapPoint(lat: 23.77, lng: 90.40));

      expect(moved.courier!.lat, 23.77);
      expect(moved.hasRoad, isTrue, reason: 'the drawn road must survive a ping');
      expect(moved.distanceMeters, 5217);
      expect(moved.etaSeconds, 987);
      expect(moved.etaLabel, '17 min');
      expect(moved.distanceLabel, '5.2 km');
      // Both ends, too — losing these would drop the pins off the map.
      expect(moved.pickup!.label, 'City Pharmacy');
      expect(moved.dropoff!.label, '5 Elm St');
      // The status is only changed when the payload names one.
      expect(moved.status, 'in_transit');
      expect(moved.movedTo(const MapPoint(lat: 1, lng: 1), status: 'delivered').status,
          'delivered');
    });

    test('reports distance and time only when they were measured', () {
      const unrouted = DeliveryRoute(status: 'assigned');
      // Never "0.0 km" or "0 min" standing in for unknown: a zero distance
      // reads as "your courier has arrived".
      expect(unrouted.distanceLabel, isNull);
      expect(unrouted.etaLabel, isNull);
      expect(unrouted.hasRoad, isFalse);
    });

    test('rounds an arrival up, and past the hour', () {
      expect(const DeliveryRoute(status: 'x', etaSeconds: 8).etaLabel, '1 min');
      expect(const DeliveryRoute(status: 'x', etaSeconds: 3900).etaLabel, '1 h 05 min');
      expect(const DeliveryRoute(status: 'x', distanceMeters: 450).distanceLabel, '450 m');
    });
  });
}
