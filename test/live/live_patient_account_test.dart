@Tags(['live'])
library;

import 'dart:io';

import 'package:bienify_app/core/constants/api_constants.dart';
import 'package:bienify_app/core/exceptions/app_exceptions.dart';
import 'package:bienify_app/core/network/api_client.dart';
import 'package:bienify_app/core/network/token_store.dart';
import 'package:bienify_app/features/Role/patient/cash_payment_process/data/repositories/api_cash_payment_repository.dart';
import 'package:bienify_app/features/Role/patient/cash_payment_process/domain/repositories/cash_payment_repository.dart';
import 'package:bienify_app/features/Role/patient/profile/data/repositories/api_account_repository.dart';
import 'package:bienify_app/features/Role/patient/wallet/data/repositories/api_wallet_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Checks the patient's account, wallet and cash-payment repositories against
/// real data — the parts of the patient app that were still on sample data
/// after the first pass.
///
///   flutter test test/live/live_patient_account_test.dart --tags live
void main() {
  late ApiAccountRepository account;
  late ApiWalletRepository wallet;
  late ApiCashPaymentRepository cash;
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
        body: {'email': 'patient@bienify.test', 'password': 'Password123!'},
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
    account = ApiAccountRepository(client);
    wallet = ApiWalletRepository(client);
    cash = ApiCashPaymentRepository(client);
  });

  Future<void> live(Future<void> Function() body) async {
    try {
      await body();
    } on TooManyRequestsException {
      // ignore: avoid_print
      print('Rate limited — skipped. Retry in 15 minutes.');
    }
  }

  group('account', () {
    test('names the signed-in patient and masks their number', () async {
      if (!up) return;
      await live(() async {
        final me = await account.me();

        expect(me.name, isNot('You'));
        expect(
          me.maskedPhone,
          endsWith('* ****'),
          reason: 'the profile card shows a partly hidden number',
        );
        expect(me.maskedPhone, isNot(contains('0000001')));
      });
    });

    test('a saved name reads back', () async {
      if (!up) return;
      await live(() async {
        final before = (await account.me()).name;
        await account.saveName(before);
        expect((await account.me()).name, before);
      });
    });
  });

  group('wallet', () {
    test('reads the balance, the ledger and the totals over it', () async {
      if (!up) return;
      await live(() async {
        final summary = await wallet.summary();

        expect(summary.balance, greaterThanOrEqualTo(0));
        expect(
          summary.transactions,
          isNotEmpty,
          reason: 'the seeded patient has paid for consultations',
        );
        expect(
          summary.transactions.map((t) => t.occurredOn.year),
          isNot(contains(1970)),
          reason: 'the epoch fallback means createdAt was not parsed',
        );
        // Summed from the ledger, so they cannot disagree with the rows.
        expect(summary.totalSpent, greaterThanOrEqualTo(0));
        expect(summary.spentOrderCount, greaterThanOrEqualTo(0));
      });
    });

    test('a card can be saved, defaulted and removed', () async {
      if (!up) return;
      await live(() async {
        // A unique token and last four per run: the server holds a unique
        // index over them, so a run that failed before its cleanup would
        // otherwise block every run after it with "That card is already
        // saved".
        final stamp = DateTime.now().millisecondsSinceEpoch;
        final last4 = (stamp % 10000).toString().padLeft(4, '0');

        final card = await wallet.addCard(
          gatewayToken: 'tok_live_check_$stamp',
          brand: 'Debit card',
          last4: last4,
          expiryMonth: 8,
          expiryYear: 2030,
        );

        expect(card.id, isNotEmpty);
        expect(card.maskedNumber, endsWith(last4));
        expect(card.expiry, '08/30');

        // Checked on the answer to the call rather than by re-reading the
        // list: this patient's cards are shared with every other live file,
        // and a card added in parallel takes the default with it.
        final defaulted = await wallet.makeCardDefault(card.id);
        expect(defaulted.id, card.id);
        expect(defaulted.isDefault, isTrue);

        await wallet.removeCard(card.id);
        expect(
          (await wallet.summary()).cards.map((c) => c.id),
          isNot(contains(card.id)),
        );
      });
    });

    test('order history reads with a store, a total and a state', () async {
      if (!up) return;
      await live(() async {
        final orders = await wallet.orders();

        expect(orders, isNotEmpty);
        expect(orders.first.reference, startsWith('#'));
        expect(orders.first.total, greaterThan(0));
        expect(
          orders.first.itemCount,
          greaterThan(0),
          reason: 'an order with no items reads as an empty basket',
        );
      });
    });
  });

  group('cash payment', () {
    test('issues a code against a real counter', () async {
      if (!up) return;
      await live(() async {
        final points = await cash.points();
        expect(points, isNotEmpty);
        expect(points.first.name, isNot('Payment point'));

        final code = await cash.issueCode(
          paymentPointId: points.first.id,
          amount: 12.34,
        );

        expect(code.code, startsWith('#'));
        expect(code.code.length, greaterThan(1));
        expect(code.amountLabel, r'$12.34');
        // The expiry is the server's to set; a client-side 24h assumption is
        // what would let a countdown outlive the code it belongs to.
        expect(code.expiresAt.isAfter(DateTime.now()), isTrue);
        expect(code.validFor, greaterThan(0));

        // Freshly issued, so it must still be pending — a code that reads as
        // confirmed here would walk the patient to a receipt for money nobody
        // has handed over.
        expect(await cash.refresh(code.code), CashIntentState.pending);
      });
    });
  });
}
