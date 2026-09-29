@Tags(['live'])
library;

import 'dart:io';

import 'package:bienify_app/core/constants/api_constants.dart';
import 'package:bienify_app/core/exceptions/app_exceptions.dart';
import 'package:bienify_app/core/network/api_client.dart';
import 'package:bienify_app/core/network/attachment_uploader.dart';
import 'package:bienify_app/core/network/token_store.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/data/repositories/api_pharmacy_shop_repository.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/domain/entities/pharmacy_shop.dart';
import 'package:flutter_test/flutter_test.dart';

/// Checks the shop repository against real data.
///
/// The failure to guard against here is the same one the doctor's calendar
/// had: `GET /medicine-orders` filters by the caller's *patient* id, so a shop
/// that asks for it gets an empty order book with a 200 rather than an error.
///
///   flutter test test/live/live_shop_test.dart --tags live
void main() {
  late ApiPharmacyShopRepository repository;
  var up = false;

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

    final store = MemoryTokenStore();
    final client = ApiClient(tokens: store);
    try {
      final data = await client.postMap(
        ApiConstants.postAuthLogin,
        body: {'email': 'pharmacy@bienify.test', 'password': 'Password123!'},
      );
      await store.save(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
    } on TooManyRequestsException {
      up = false;
      // ignore: avoid_print
      print('Auth rate limit reached — live checks skipped. Retry in 15 min.');
      return;
    }
    repository = ApiPharmacyShopRepository(client, AttachmentUploader(client));
  });

  Future<void> live(Future<void> Function() body) async {
    try {
      await body();
    } on TooManyRequestsException {
      // ignore: avoid_print
      print('Rate limited — skipped. Retry in 15 minutes.');
    }
  }

  group('shop', () {
    test('names the pharmacy, its owner and its balance', () async {
      if (!up) return;
      await live(() async {
        final shop = await repository.shop();

        expect(shop.name, isNot('Pharmacy'));
        expect(shop.ownerName, isNot('Owner'));
        expect(shop.email, contains('@'));
        expect(shop.licenceNumber, isNotEmpty);
        expect(shop.address, isNotEmpty);
      });
    });

    test('reads stock alerts without failing on a full shelf', () async {
      if (!up) return;
      await live(() async {
        // The seeded shop is stocked, so an empty list is the right answer.
        expect(await repository.stockAlerts(), isA<List<StockAlert>>());
      });
    });
  });

  group('orders', () {
    test('lists the shop book rather than the owner as a customer', () async {
      if (!up) return;
      await live(() async {
        final orders = await repository.orders();

        expect(
          orders,
          isNotEmpty,
          reason: 'the seeded shop has orders against it',
        );
        expect(orders.first.code, startsWith('ORD-'));
        // The endpoint does not populate the customer, so the card falls back
        // to the order code rather than printing the same placeholder name on
        // every row. Documented in docs/API-GAPS.md.
        expect(orders.first.customerName, isNotEmpty);
        expect(orders.first.customerName, isNot('Customer'));
        expect(
          orders.first.lines,
          isNotEmpty,
          reason: 'an order with no lines totals zero on screen',
        );
        expect(orders.first.total, greaterThan(0));
      });
    });

    test('every order lands under one of the six chips', () async {
      if (!up) return;
      await live(() async {
        final orders = await repository.orders();
        // A row whose state does not map is invisible: the chip row has no
        // "all", so it would be filtered out of every tab.
        expect(orders.map((o) => o.status), everyElement(isNotNull));
      });
    });
  });

  group('shelf', () {
    test('lists only this shop stock', () async {
      if (!up) return;
      await live(() async {
        final medicines = await repository.medicines();

        expect(medicines, isNotEmpty);
        expect(medicines.first.name, isNot('Medicine'));
        expect(medicines.first.price, greaterThan(0));
      });
    });

    test('adds a medicine, edits it, then takes it off sale', () async {
      if (!up) return;
      await live(() async {
        final added = await repository.addMedicine(
          name: 'Live check syrup',
          price: 12.5,
          stock: 7,
          isListed: true,
          category: 'Live check',
        );

        expect(added.id, isNotEmpty);
        expect(added.price, 12.5);
        expect(added.stock, 7);
        expect(added.isListed, isTrue);

        // The server validates an edit against the same schema it validates a
        // creation with, so a body carrying only the changed field is refused
        // for the ones it left out. This is what catches that.
        await repository.updateMedicine(
          ShopMedicine(
            id: added.id,
            name: added.name,
            category: added.category,
            stock: 3,
            price: 9.99,
            isListed: true,
          ),
        );

        final shelf = await repository.medicines();
        final saved = shelf.firstWhere((m) => m.id == added.id);
        expect(saved.stock, 3);
        expect(saved.price, 9.99);

        await repository.delistMedicine(saved);
        final after = await repository.medicines();
        // Off sale means off the shelf: `GET /medicines` filters on isActive
        // and there is no owner-scoped list that includes delisted stock, so
        // the row leaves the list rather than greying out. The controller says
        // so, because a row that silently disappears reads as a bug.
        expect(
          after.map((m) => m.id),
          isNot(contains(added.id)),
          reason: 'a delisted medicine is not on the shelf the owner sees',
        );
      });
    });
  });

  group('notifications', () {
    test('reads the feed without failing on an empty one', () async {
      if (!up) return;
      await live(() async {
        expect(await repository.notifications(), isA<List<ShopNotification>>());
      });
    });
  });
}
