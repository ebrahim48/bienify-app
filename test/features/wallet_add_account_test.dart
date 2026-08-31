// What the Wallet's "Add Account" actually adds.
//
// It used to add a card whichever method was chosen. Payment Options listed
// six — including Bank Transfer — and `continueToCardForm` ignored the
// selection and opened the debit-card form for all of them, filing the result
// to `/wallet/cards`. That is the collection money is taken *in* from; a
// payout goes *out* to `/wallet/payout-accounts`, a separate list the Wallet
// never wrote to. So a courier added their bank account here, saw it appear in
// the Wallet, and was then told by the payout sheet to add a payout account
// first — with no way to reconcile the two.
import 'package:bienify_app/core/routes/app_routes.dart';
import 'package:bienify_app/features/Role/doctor_role/domain/entities/doctor_practice.dart'
    show PayoutAccount;
import 'package:bienify_app/features/Role/patient/booking/domain/entities/payment_method.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/domain/repositories/pharmacy_repository.dart';
import 'package:bienify_app/features/Role/patient/profile/domain/entities/profile.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/controllers/account_controller.dart';
import 'package:bienify_app/features/Role/patient/wallet/domain/repositories/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Records what was filed, and where.
class _FakeWalletRepository implements WalletRepository {
  final List<Map<String, String?>> payoutAccountsAdded = <Map<String, String?>>[];
  final List<PayoutAccount> stored = <PayoutAccount>[];

  int cardsAdded = 0;

  @override
  Future<WalletSummary> summary() async => const WalletSummary(
    balance: 45,
    cards: [],
    transactions: [],
    totalSpent: 0,
    addedThisMonth: 0,
    spentOrderCount: 0,
  );

  @override
  Future<double> balance() async => 45;

  @override
  Future<List<OrderHistoryEntry>> orders() async => const [];

  @override
  Future<List<PayoutAccount>> payoutAccounts() async => List.of(stored);

  @override
  Future<PayoutAccount> addPayoutAccount({
    required String kind,
    required String displayName,
    required String accountNumber,
    String? bankName,
  }) async {
    payoutAccountsAdded.add({
      'kind': kind,
      'displayName': displayName,
      'accountNumber': accountNumber,
      'bankName': bankName,
    });
    final account = PayoutAccount(
      id: 'payout-${stored.length + 1}',
      label: '$displayName ••••${accountNumber.substring(accountNumber.length - 4)}',
      isDefault: stored.isEmpty,
    );
    stored.add(account);
    return account;
  }

  @override
  Future<WalletCard> addCard({
    required String gatewayToken,
    required String brand,
    required String last4,
    required int expiryMonth,
    required int expiryYear,
  }) async {
    cardsAdded++;
    return WalletCard(
      id: 'card-1',
      brand: brand,
      maskedNumber: '•••• $last4',
      expiry: '01/30',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePharmacyRepository implements PharmacyRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeWalletRepository wallet;
  late AccountController controller;

  setUp(() async {
    wallet = _FakeWalletRepository();
    controller = AccountController(
      repository: wallet,
      pharmacy: _FakePharmacyRepository(),
    );
    await controller.load();
  });

  tearDown(Get.reset);

  /// A mounted app, because `savePayoutAccount` reports through `AppSnackbar`
  /// and GetX's snackbar needs a navigator to attach to.
  Future<void> mountApp(WidgetTester tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold()),
    );
    await tester.pump();
  }

  test('Payment Options offers only the methods that store something', () {
    final options = controller.methodOptions;

    // These three the Wallet can genuinely file: a card, a bank account, a
    // mobile-money number.
    expect(options, contains(PaymentMethod.debitCredit));
    expect(options, contains(PaymentMethod.bankTransfer));
    expect(options, contains(PaymentMethod.tpago));

    // These are ways to settle a bill at the moment of paying. The API has
    // nowhere to keep them and there is no form for them, so offering them
    // under "Add Account" only ever led to the card form.
    expect(options, isNot(contains(PaymentMethod.appleGooglePay)));
    expect(options, isNot(contains(PaymentMethod.paypal)));
    expect(options, isNot(contains(PaymentMethod.cashOnLocation)));
  });

  test('a bank transfer files a bank payout account, not a card', () {
    expect(PaymentMethod.bankTransfer.payoutKind, 'bank');
    expect(PaymentMethod.debitCredit.payoutKind, isNull);
  });

  test('tPago files a mobile-money payout account', () {
    expect(PaymentMethod.tpago.payoutKind, 'mobile_money');
  });

  testWidgets('Next opens the form the chosen method actually needs', (
    tester,
  ) async {
    Get.put<AccountController>(controller);

    // A navigator that records where it was sent rather than building the
    // real screens, which is what this asserts on.
    final visited = <String>[];
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const Scaffold()),
          for (final route in [AppRoutes.addDebitCard, AppRoutes.addPayoutAccount])
            GetPage(
              name: route,
              page: () {
                visited.add(route);
                return const Scaffold();
              },
              transition: Transition.noTransition,
            ),
        ],
      ),
    );

    final options = controller.methodOptions;

    controller.selectMethod(options.indexOf(PaymentMethod.debitCredit));
    controller.continueToAccountForm();
    await tester.pumpAndSettle();
    expect(visited.last, AppRoutes.addDebitCard);
    Get.back<void>();
    await tester.pumpAndSettle();

    // The one that was broken: Bank Transfer used to land on the card form.
    controller.selectMethod(options.indexOf(PaymentMethod.bankTransfer));
    controller.continueToAccountForm();
    await tester.pumpAndSettle();
    expect(visited.last, AppRoutes.addPayoutAccount);
    // And it carries which kind to file, so the form does not ask again.
    expect(Get.arguments, 'bank');
  });

  testWidgets('an account added in the Wallet is the one the payout sheet can use', (
    tester,
  ) async {
    await mountApp(tester);
    final saved = await controller.savePayoutAccount(
      kind: PaymentMethod.bankTransfer.payoutKind!,
      displayName: 'Sam Rider',
      accountNumber: '12349494',
      bankName: 'First National',
    );

    expect(saved, isTrue);
    expect(wallet.cardsAdded, 0);
    expect(wallet.payoutAccountsAdded.single['kind'], 'bank');

    // Present without re-adding: the payout sheet reads this same list, so a
    // courier who filed an account in the Wallet finds it already there.
    expect(controller.payoutAccounts.single.label, contains('••••9494'));
    expect(controller.payoutAccounts.single.isDefault, isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('an account number too short to mask is refused before the request', (
    tester,
  ) async {
    await mountApp(tester);
    final saved = await controller.savePayoutAccount(
      kind: 'bank',
      displayName: 'Sam Rider',
      accountNumber: '12',
    );

    expect(saved, isFalse);
    expect(wallet.payoutAccountsAdded, isEmpty);
    await tester.pumpAndSettle();
  });
}
