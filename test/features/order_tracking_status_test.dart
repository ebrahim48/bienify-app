// A pushed state change, with no position attached.
//
// The server broadcasts `delivery:location` for two different reasons: a
// courier reported a position, and a courier moved the parcel to a new state.
// The second carries no coordinates — a delivery whose courier has not pinged
// yet has none — and it used to go out claiming `lat: undefined, lng:
// undefined`, which this controller discarded wholesale rather than draw a pin
// at nowhere. The state change went into the bin with the missing position, so
// a patient watching the map stayed on "ready" while the parcel was already on
// the road, until the thirty-second poll caught up.
import 'dart:async';

import 'package:bienify_app/core/network/socket_service.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/domain/entities/pharmacy.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/domain/repositories/pharmacy_repository.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/presentation/controllers/order_tracking_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Feeds the controller socket payloads by hand.
///
/// `implements` rather than `extends`: the real service opens a connection and
/// subscribes to the token store in its constructor, neither of which a test
/// of this controller has any business doing.
class _FakeSocket implements SocketService {
  final _locations = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get deliveryLocations => _locations.stream;

  void push(Map<String, dynamic> payload) => _locations.add(payload);

  Future<void> close() => _locations.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The order read is not what is under test; leaving it empty keeps
/// `loadRoute` from reaching for a delivery that does not exist.
class _FakePharmacyRepository implements PharmacyRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeSocket socket;
  late OrderTrackingController controller;

  setUp(() {
    socket = _FakeSocket();
    controller = OrderTrackingController(
      repository: _FakePharmacyRepository(),
      socket: socket,
    );
    // What the screen would have learnt from its first read. Set directly
    // because the read itself needs an order, and the delivery being watched
    // is the only part of it this behaviour depends on.
    controller.watchedDeliveryId = 'd-1';
    controller.startTrackingUpdates();
  });

  tearDown(() async {
    controller.stopTrackingUpdates();
    await socket.close();
  });

  /// Lets the broadcast stream deliver before the assertion reads the result.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('a state change with no position still moves the parcel along', () async {
    controller.route.value = DeliveryRoute(
      status: 'assigned',
      courier: const MapPoint(lat: 42.1, lng: -72.5),
      pickup: const MapPoint(lat: 42.0, lng: -72.4),
      dropoff: const MapPoint(lat: 42.2, lng: -72.6),
      reportedAt: DateTime.utc(2026, 8, 28, 12),
      path: const [MapPoint(lat: 42.1, lng: -72.5), MapPoint(lat: 42.2, lng: -72.6)],
      distanceMeters: 3000,
      etaSeconds: 240,
    );

    socket.push({'deliveryId': 'd-1', 'status': 'picked_up'});
    await settle();

    final route = controller.route.value!;
    expect(route.status, 'picked_up');

    // And nothing else moved with it. The courier is where they were — a
    // state change is not a sighting — and the road, its length and the
    // arrival time were not read again, so the last known ones stand.
    expect(route.courier, const MapPoint(lat: 42.1, lng: -72.5));
    expect(route.reportedAt, DateTime.utc(2026, 8, 28, 12));
    expect(route.path.length, 2);
    expect(route.distanceMeters, 3000);
    expect(route.etaSeconds, 240);
  });

  test('a state change arriving before any read is not dropped', () async {
    expect(controller.route.value, isNull);

    socket.push({'deliveryId': 'd-1', 'status': 'in_transit'});
    await settle();

    expect(controller.route.value?.status, 'in_transit');
  });

  test('an event for another delivery is ignored', () async {
    socket.push({'deliveryId': 'd-2', 'status': 'delivered'});
    await settle();

    expect(controller.route.value, isNull);
  });

  test('an event carrying neither a position nor a state changes nothing', () async {
    socket.push({'deliveryId': 'd-1'});
    await settle();

    expect(controller.route.value, isNull);
  });
}
