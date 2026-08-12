@Tags(['live'])
library;

import 'dart:io';

import 'package:bienify_app/core/constants/api_constants.dart';
import 'package:bienify_app/core/exceptions/app_exceptions.dart';
import 'package:bienify_app/core/network/api_client.dart';
import 'package:bienify_app/core/network/mappers.dart';
import 'package:bienify_app/core/network/token_store.dart';
import 'package:bienify_app/features/Role/rider_role/data/repositories/api_rider_repository.dart';
import 'package:bienify_app/features/Role/rider_role/domain/entities/rider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Checks the courier repository against real data.
///
/// The seed ships no deliveries, so this makes one: a patient orders and pays,
/// the shop hands it to the delivery service, and the courier then sees it on
/// the board. Testing the board against an empty database would pass without
/// proving anything.
///
///   flutter test test/live/live_rider_test.dart --tags live
void main() {
  late ApiRiderRepository repository;
  late ApiClient patient;
  late ApiClient pharmacy;
  var up = false;

  Future<ApiClient> signIn(String email) async {
    final store = MemoryTokenStore();
    final client = ApiClient(tokens: store);
    final data = await client.postMap(
      ApiConstants.postAuthLogin,
      body: {'email': email, 'password': 'Password123!'},
    );
    await store.save(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    return client;
  }

  setUpAll(() async {
    try {
      final probe = HttpClient()
        ..connectionTimeout = const Duration(seconds: 3);
      final res = await (await probe.getUrl(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.health}'),
      )).close();
      await res.drain<void>();
      probe.close();
      up = res.statusCode == 200;
    } catch (_) {
      up = false;
    }
    if (!up) return;

    try {
      repository = ApiRiderRepository(await signIn('rider@bienify.test'));
      patient = await signIn('patient@bienify.test');
      pharmacy = await signIn('pharmacy@bienify.test');
    } on TooManyRequestsException {
      up = false;
      // ignore: avoid_print
      print('Auth rate limit reached — live checks skipped. Retry in 15 min.');
    }
  });

  Future<void> live(Future<void> Function() body) async {
    try {
      await body();
    } on TooManyRequestsException {
      // ignore: avoid_print
      print('Rate limited — skipped. Retry in 15 minutes.');
    }
  }

  /// Places, pays for and dispatches an order, and returns its delivery id.
  Future<String> makeDelivery() async {
    final shop = await pharmacy.getMap(ApiConstants.pharmaciesMe);
    // Over-the-counter only: an order carrying a prescription-only medicine is
    // refused until a script is attached, which is a different flow.
    //
    // Narrowed here rather than with `?requiresPrescription=false`, which the
    // server does not honour — its `z.coerce.boolean()` reads the *string*
    // "false" as true, so the filter returns exactly what it excludes. Noted
    // in docs/API-GAPS.md.
    final stock =
        (await pharmacy.getList(
              ApiConstants.medicines,
              query: {'pharmacyId': Api.id(shop), 'limit': 100},
            ))
            .where(
              (m) =>
                  m['requiresPrescription'] != true &&
                  Api.integer(m['stock']) > 0,
            )
            .toList();

    final order = await patient.postMap(
      ApiConstants.postMedicineOrders,
      body: {
        'pharmacyId': Api.id(shop),
        'items': [
          {'medicineId': Api.id(stock.first), 'quantity': 1},
        ],
        'deliveryAddress': '12 Oak Avenue, Springfield',
      },
    );
    final orderId = Api.id(order);

    await patient.post(ApiConstants.postMedicineOrdersPay(orderId));

    // Only a `ready` order can be handed over, and the order book runs on a
    // transition table — so the shop has to walk it there one step at a time.
    for (final status in ['accepted', 'preparing', 'ready']) {
      await pharmacy.patch(
        ApiConstants.updateMedicineOrdersStatus(orderId),
        body: {'status': status},
      );
    }

    final delivery = await pharmacy.postMap(
      ApiConstants.postDeliveries,
      body: {'orderId': orderId},
    );
    return Api.id(delivery);
  }

  group('rider', () {
    test('names the courier and reads their standing', () async {
      if (!up) return;
      await live(() async {
        final rider = await repository.rider();

        expect(rider.name, isNot('Rider'));
        expect(rider.email, contains('@'));
        expect(rider.licenceNumber, isNotEmpty);
        expect(rider.vehicleType, isNotEmpty);
        expect(rider.city, isNotEmpty);
      });
    });

    test('going offline and back on sticks', () async {
      if (!up) return;
      await live(() async {
        await repository.setOnline(isOnline: false);
        expect((await repository.rider()).isOnline, isFalse);

        await repository.setOnline(isOnline: true);
        expect(
          (await repository.rider()).isOnline,
          isTrue,
          reason: 'a courier who cannot come back online cannot work',
        );
      });
    });
  });

  group('board', () {
    test('shows a dispatched order as a job the courier can take', () async {
      if (!up) return;
      await live(() async {
        final deliveryId = await makeDelivery();
        final board = await repository.requests();

        final job = board.firstWhere(
          (r) => r.id == deliveryId,
          orElse: () =>
              throw StateError('the new delivery is not on the board'),
        );
        expect(job.tab, RequestTab.fresh);
        expect(job.code, startsWith('ORD-'));
        expect(
          job.customerAddress,
          isNotEmpty,
          reason: 'a courier cannot deliver to an address they cannot see',
        );
        expect(job.pickupName, isNotEmpty);
      });
    });

    test('claiming a job moves it under Accepted', () async {
      if (!up) return;
      await live(() async {
        final deliveryId = await makeDelivery();
        await repository.claim(deliveryId);

        final board = await repository.requests();
        final job = board.firstWhere((r) => r.id == deliveryId);
        expect(
          job.tab,
          RequestTab.accepted,
          reason: 'a claimed job belongs to this courier, not the board',
        );
      });
    });

    test('a job runs from pickup through to delivered', () async {
      if (!up) return;
      await live(() async {
        final deliveryId = await makeDelivery();
        await repository.claim(deliveryId);

        // The server holds a transition table, so these have to go in order —
        // jumping straight to delivered is refused.
        await repository.setStatus(deliveryId, 'picked_up');
        await repository.setStatus(deliveryId, 'in_transit');
        await repository.setStatus(deliveryId, 'delivered');

        final board = await repository.requests();
        expect(
          board.firstWhere((r) => r.id == deliveryId).tab,
          RequestTab.accepted,
        );
      });
    });
  });

  group('earnings', () {
    test('reports the courier week and the payout threshold', () async {
      if (!up) return;
      await live(() async {
        final earnings = await repository.earnings();

        expect(earnings.payoutMinimum, greaterThan(0));
        expect(earnings.history, isA<List<DeliveryRecord>>());
        expect(earnings.payoutProgress, inInclusiveRange(0, 1));
      });
    });
  });
}
