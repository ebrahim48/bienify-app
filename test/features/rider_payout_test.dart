// Asking to be paid: the empty state, the form out of it, and the withdrawal.
//
// This path had no test at all, and it is the one a courier gets stuck in. Two
// separate failures reached a real device through it: the sheet told a courier
// to "add a payout account first" while offering no form to add one, and — once
// the form existed — a payout-account read that failed was reported with that
// same sentence, so a backend that was not running looked exactly like a
// courier who had never filed an account. A saved debit card does not help
// with either: cards pay for orders, payouts need a bank or mobile-money
// account, and they are different collections on the server.
import 'package:bienify_app/core/exceptions/app_exceptions.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/Role/doctor_role/domain/entities/doctor_practice.dart'
    show PayoutAccount;
import 'package:bienify_app/features/Role/patient/auth/domain/usecases/email_auth_usecases.dart';
import 'package:bienify_app/features/Role/rider_role/domain/entities/rider.dart';
import 'package:bienify_app/features/Role/rider_role/domain/repositories/rider_repository.dart';
import 'package:bienify_app/features/Role/rider_role/presentation/controllers/rider_profile_controller.dart';
import 'package:bienify_app/features/Role/rider_role/presentation/widgets/rider_payout_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../support/test_fonts.dart';

/// A courier with money, and whatever payout accounts the test says.
///
/// [payoutFailure], when set, is thrown by the payout-account read — which is
/// what a stopped backend, an expired session or a 500 all look like from
/// here, and the case the sheet used to misreport.
class _FakeRiderRepository implements RiderRepository {
  _FakeRiderRepository({List<PayoutAccount>? accounts, this.payoutFailure})
    : accounts = accounts ?? <PayoutAccount>[];

  final List<PayoutAccount> accounts;
  final AppException? payoutFailure;

  /// What was filed, so a saved account can be asserted on rather than a call
  /// merely having happened.
  final List<Map<String, String?>> added = <Map<String, String?>>[];

  /// Amount and destination of every withdrawal asked for.
  final List<(double, String)> withdrawals = <(double, String)>[];

  int payoutAccountReads = 0;

  @override
  Future<List<PayoutAccount>> payoutAccounts() async {
    payoutAccountReads++;
    final failure = payoutFailure;
    if (failure != null) throw failure;
    return List.of(accounts);
  }

  @override
  Future<void> addPayoutAccount({
    required String kind,
    required String displayName,
    required String accountNumber,
    String? bankName,
  }) async {
    added.add({
      'kind': kind,
      'displayName': displayName,
      'accountNumber': accountNumber,
      'bankName': bankName,
    });
    // The server masks the number down to its last four digits and makes the
    // first account the default, so the list this read serves next says the
    // same — a fixture that returned the raw number would let a bug through.
    accounts.add(
      PayoutAccount(
        id: 'pa-${accounts.length + 1}',
        label: '$displayName ••••${accountNumber.substring(accountNumber.length - 4)}',
        isDefault: accounts.isEmpty,
      ),
    );
  }

  @override
  Future<void> requestWithdrawal({
    required double amount,
    required String payoutAccountId,
  }) async => withdrawals.add((amount, payoutAccountId));

  @override
  Future<Rider> rider() async => const Rider(
    name: 'Sam Rider',
    location: 'Springfield',
    todaysEarnings: 0,
    deliveriesToday: 0,
    rating: 0,
    isOnline: true,
    email: 'rider@bienify.test',
    country: 'United States',
    city: 'Springfield',
    address: '1 Elm St',
  );

  @override
  Future<RiderEarnings> earnings() async => const RiderEarnings(
    today: 10,
    todayCount: 1,
    thisWeek: 192,
    weekCount: 96,
    payoutDay: 'Friday',
    payoutMinimum: 10,
    history: [],
    available: 440,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The controller takes one, and signing out is not what is under test here.
class _NoopLogout implements Logout {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(loadAppFonts);

  tearDown(Get.reset);

  /// The field carrying [hint], rather than a positional guess at it.
  Finder fieldFor(String hint) => find.ancestor(
    of: find.text(hint),
    matching: find.byType(TextField),
  );

  Future<RiderProfileController> open(
    WidgetTester tester,
    _FakeRiderRepository repository,
  ) async {
    final controller = Get.put(
      RiderProfileController(repository: repository, logout: _NoopLogout()),
    );
    await controller.load();

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 876),
        builder: (context, _) => GetMaterialApp(
          theme: AppTheme.light,
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => RiderPayoutDialog.show(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets(
    'a courier with no payout account is offered the form, not just told to add one',
    (tester) async {
      final repository = _FakeRiderRepository();
      await open(tester, repository);

      // The empty state, and the line saying why a saved card is not one —
      // both are what a courier reads before deciding the app has lost their
      // card.
      expect(find.text('Add a payout account first'), findsOneWidget);
      expect(
        find.textContaining('A saved card pays for orders'),
        findsOneWidget,
      );

      // The way out of it. Without this button the empty state is terminal,
      // which is exactly how it shipped.
      await tester.tap(find.text('Add payout Account'));
      await tester.pumpAndSettle();

      expect(find.text('Account name'), findsOneWidget);
    },
  );

  testWidgets('an account filed through the form becomes payable', (
    tester,
  ) async {
    final repository = _FakeRiderRepository();
    await open(tester, repository);

    await tester.tap(find.text('Add payout Account'));
    await tester.pumpAndSettle();

    // Located by their hints rather than by index: the payout sheet's own
    // amount field is still mounted behind this dialog, so `TextField` at 0 is
    // that one and typing the account name into it silently files an empty
    // name.
    await tester.enterText(fieldFor('Account name'), 'Sam Rider');
    await tester.enterText(fieldFor('Account number'), '12349494');
    await tester.enterText(fieldFor('Bank name (optional)'), 'First National');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Filed as the server's own spelling of the kind, not the pill's label —
    // `bank | mobile_money` is the whole enum it accepts.
    expect(repository.added.single['kind'], 'bank');
    expect(repository.added.single['displayName'], 'Sam Rider');
    expect(repository.added.single['accountNumber'], '12349494');

    // And the sheet behind it now has somewhere to pay, rather than still
    // showing the empty state it was opened on.
    expect(find.text('Add a payout account first'), findsNothing);
    expect(find.textContaining('••••9494'), findsOneWidget);

    // The withdrawal itself, which is what the account was added for.
    await tester.enterText(fieldFor('Amount to withdraw'), '25');
    // `.last` because "Request Payout" is both the sheet's title and its
    // button, and the title comes first in the tree.
    await tester.tap(find.text('Request Payout').last);
    await tester.pumpAndSettle();

    expect(repository.withdrawals.single.$1, 25);
    expect(repository.withdrawals.single.$2, 'pa-1');
  });

  testWidgets(
    'a payout-account read that failed is not reported as having none',
    (tester) async {
      final repository = _FakeRiderRepository(
        payoutFailure: ServerUnreachableException('http://localhost:3500'),
      );
      await open(tester, repository);

      expect(repository.payoutAccountReads, greaterThan(0));

      // The distinction that matters: the app does not know, and says so,
      // instead of asserting the courier has no account. It also names why,
      // since "cannot reach the server" is the fact that leads to the fix.
      expect(find.text('Could not load your payout accounts'), findsOneWidget);
      expect(
        find.textContaining('Cannot reach the server at http://localhost:3500'),
        findsOneWidget,
      );
      expect(find.text('Add a payout account first'), findsNothing);
      expect(
        find.textContaining('A saved card pays for orders'),
        findsNothing,
      );
    },
  );
}
