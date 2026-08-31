// Adding money to the wallet.
//
// The wallet is how consultations and medicine are paid for, and the only ways
// into it were the seed script, a refund and a cash payment an admin confirmed.
// `POST /wallet/topup` existed and no screen called it.
//
// The assertions here are about money, so they are about exact integers: the
// server takes minor units, and a rounding slip is a real shortfall on a real
// payment rather than a display bug.
import 'package:bienify_app/core/exceptions/app_exceptions.dart';
import 'package:bienify_app/features/Role/doctor_role/domain/entities/doctor_practice.dart'
    show PayoutAccount;
import 'package:bienify_app/features/Role/patient/pharmacy/domain/repositories/pharmacy_repository.dart';
import 'package:bienify_app/features/Role/patient/profile/domain/entities/profile.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/controllers/account_controller.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/controllers/top_up_controller.dart';
import 'package:bienify_app/features/Role/patient/wallet/domain/repositories/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _RecordingWallet implements WalletRepository {
  _RecordingWallet({this.cards = const []});

  final List<WalletCard> cards;
  final List<Map<String, Object>> topUps = <Map<String, Object>>[];

  /// Set to answer the way the server does when the ledger already holds this
  /// movement — the money moved and the response was lost.
  bool alreadyProcessed = false;

  /// Set to fail the charge outright, as a decline does.
  bool decline = false;

  int loads = 0;

  @override
  Future<WalletSummary> summary() async {
    loads++;
    return WalletSummary(
      balance: 45,
      cards: cards,
      transactions: const [],
      totalSpent: 0,
      addedThisMonth: 0,
      spentOrderCount: 0,
    );
  }

  @override
  Future<List<OrderHistoryEntry>> orders() async => const [];

  @override
  Future<List<PayoutAccount>> payoutAccounts() async => const [];

  @override
  Future<WalletTopUp> topUp({
    required int amountMinor,
    required String savedCardId,
    required String idempotencyKey,
  }) async {
    topUps.add({
      'amountMinor': amountMinor,
      'savedCardId': savedCardId,
      'idempotencyKey': idempotencyKey,
    });
    if (alreadyProcessed) {
      throw ConflictException('This payment has already been processed');
    }
    if (decline) throw ValidationException('Card declined');
    return WalletTopUp(
      transaction: WalletTransaction(
        id: 'txn-${topUps.length}',
        title: 'Top-up',
        occurredOn: DateTime(2026, 8, 29),
        amount: amountMinor / 100,
        kind: TransactionKind.credit,
      ),
      balanceAfter: 45 + amountMinor / 100,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubPharmacy implements PharmacyRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

WalletCard _card(String id, {bool isDefault = false}) => WalletCard(
  id: id,
  brand: 'Debit card',
  maskedNumber: '•••• 4242',
  expiry: '08/30',
  isDefault: isDefault,
);

void main() {
  late _RecordingWallet wallet;
  late AccountController account;
  late TopUpController controller;

  Future<void> setUpWith(List<WalletCard> cards) async {
    wallet = _RecordingWallet(cards: cards);
    account = AccountController(
      repository: wallet,
      pharmacy: _StubPharmacy(),
    );
    await account.load();
    controller = TopUpController(repository: wallet, account: account);
    controller.onInit();
  }

  tearDown(Get.reset);

  Future<void> mountApp(WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
    await tester.pump();
  }

  group('the amount', () {
    setUp(() => setUpWith([_card('card-1', isDefault: true)]));

    test('converts to minor units by rounding, never truncating', () {
      // `(0.29 * 100).toInt()` is 28 in IEEE-754. Truncating here is a silent
      // one-cent shortfall on every amount that lands on the wrong side of a
      // float, which is why this is asserted rather than assumed.
      controller.setAmount('0.29');
      expect(controller.amountMinor, 29);

      controller.setAmount('29.99');
      expect(controller.amountMinor, 2999);

      controller.setAmount('50');
      expect(controller.amountMinor, 5000);
    });

    test('accepts a comma as the decimal separator', () {
      controller.setAmount('12,50');
      expect(controller.amountMinor, 1250);
    });

    test('refuses what the server would refuse', () {
      controller.setAmount('');
      expect(controller.isAmountValid, isFalse);

      controller.setAmount('abc');
      expect(controller.isAmountValid, isFalse);

      // Below the floor: a one-cent top-up costs more in fees than it moves.
      controller.setAmount('0.50');
      expect(controller.isAmountValid, isFalse);

      // Above what `topupSchema` accepts.
      controller.setAmount('9999999');
      expect(controller.isAmountValid, isFalse);

      controller.setAmount('1.00');
      expect(controller.isAmountValid, isTrue);
    });

    test('a quick chip and the field cannot disagree', () {
      controller.selectQuickAmount(25);
      expect(controller.amountMinor, 2500);
      expect(controller.isQuickAmountSelected(25), isTrue);

      // Typing over it deselects the chip, because selection is read off the
      // amount rather than stored beside it.
      controller.setAmount('30');
      expect(controller.isQuickAmountSelected(25), isFalse);
    });

    test('previews the balance only once the amount is usable', () {
      expect(controller.newBalanceLabel, isNull);

      controller.setAmount('0.50');
      expect(controller.newBalanceLabel, isNull);

      controller.setAmount('55');
      expect(controller.newBalanceLabel, r'$100.00');
    });
  });

  group('the card', () {
    test('defaults to the one the server marked default', () async {
      await setUpWith([_card('card-1'), _card('card-2', isDefault: true)]);
      // Not the first row, which is only the newest.
      expect(controller.selectedCardId.value, 'card-2');
    });

    test('with no card saved, nothing can be submitted', () async {
      await setUpWith([]);
      controller.setAmount('50');

      expect(controller.hasCard, isFalse);
      expect(controller.canSubmit, isFalse);
    });
  });

  group('submitting', () {
    setUp(() => setUpWith([_card('card-1', isDefault: true)]));

    testWidgets('sends the amount in minor units against the chosen card', (
      tester,
    ) async {
      await mountApp(tester);
      controller.setAmount('25.50');

      await controller.addMoney();
      await tester.pumpAndSettle();

      expect(wallet.topUps, hasLength(1));
      expect(wallet.topUps.single['amountMinor'], 2550);
      expect(wallet.topUps.single['savedCardId'], 'card-1');
    });

    testWidgets('credits the balance from the server figure', (tester) async {
      await mountApp(tester);
      controller.setAmount('55');

      await controller.addMoney();
      await tester.pumpAndSettle();

      // 45 + 55, taken from the response rather than added up locally.
      expect(account.balance.value, 100);
      expect(account.transactions.first.amount, 55);
      expect(account.transactions.first.kind, TransactionKind.credit);
    });

    testWidgets('an invalid amount sends nothing', (tester) async {
      await mountApp(tester);
      controller.setAmount('0.50');

      await controller.addMoney();
      await tester.pumpAndSettle();

      expect(wallet.topUps, isEmpty);
      expect(
        controller.errorOf(TopUpController.amountField),
        isNotNull,
      );
    });

    testWidgets('a decline credits nothing', (tester) async {
      await mountApp(tester);
      wallet.decline = true;
      controller.setAmount('50');

      await controller.addMoney();
      await tester.pumpAndSettle();

      expect(account.balance.value, 45);
      expect(account.transactions, isEmpty);
    });
  });

  group('idempotency', () {
    setUp(() => setUpWith([_card('card-1', isDefault: true)]));

    testWidgets('a retry of the same attempt reuses the key', (tester) async {
      await mountApp(tester);
      wallet.decline = true;
      controller.setAmount('50');

      await controller.addMoney();
      await controller.addMoney();
      await tester.pumpAndSettle();

      expect(wallet.topUps, hasLength(2));
      // The same key: the server's duplicate handling is what stops a lost
      // response becoming a second real charge.
      expect(
        wallet.topUps[0]['idempotencyKey'],
        wallet.topUps[1]['idempotencyKey'],
      );
    });

    testWidgets('editing the amount starts a new attempt', (tester) async {
      await mountApp(tester);
      wallet.decline = true;
      controller.setAmount('50');
      await controller.addMoney();

      controller.setAmount('60');
      await controller.addMoney();
      await tester.pumpAndSettle();

      // A different amount is a deliberate second top-up, not a retry — reusing
      // the key would make the server treat it as one and charge nothing.
      expect(
        wallet.topUps[0]['idempotencyKey'],
        isNot(wallet.topUps[1]['idempotencyKey']),
      );
    });

    testWidgets('"already processed" is a success, not a failure', (
      tester,
    ) async {
      await mountApp(tester);
      wallet.alreadyProcessed = true;
      controller.setAmount('50');
      final loadsBefore = wallet.loads;

      await controller.addMoney();
      await tester.pumpAndSettle();

      // The money moved and the response was lost. Reporting a failure here
      // invites a second, real charge — so the wallet is re-read instead.
      expect(wallet.loads, greaterThan(loadsBefore));
      expect(controller.amount.value, '');
    });
  });
}
