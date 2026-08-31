import '../../../../doctor_role/domain/entities/doctor_practice.dart'
    show PayoutAccount;
import '../../../profile/data/static/profile_mock_data.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../domain/repositories/wallet_repository.dart';

/// A fixed wallet, so the payment and account screens render the same way
/// every run.
class MockWalletRepository implements WalletRepository {
  // Not `const`: payout accounts filed offline are held here, so the Wallet
  // and the payout sheet both see one that was just added, the same way the
  // doctor's static repository already does.
  MockWalletRepository({this.amount = 45});

  final double amount;

  /// Credited offline so the Wallet moves the way the live one does: top up
  /// twice and the balance is higher twice.
  double _credited = 0;

  final List<PayoutAccount> _payoutAccounts = <PayoutAccount>[];

  @override
  Future<double> balance() async => amount + _credited;

  @override
  Future<WalletTopUp> topUp({
    required int amountMinor,
    required String savedCardId,
    required String idempotencyKey,
  }) async {
    final major = amountMinor / 100;
    _credited += major;
    return WalletTopUp(
      transaction: WalletTransaction(
        id: 'topup-${DateTime.now().microsecondsSinceEpoch}',
        title: 'Top-up',
        occurredOn: DateTime.now(),
        amount: major,
        kind: TransactionKind.credit,
      ),
      balanceAfter: ProfileMockData.walletBalance + _credited,
    );
  }

  @override
  Future<WalletSummary> summary() async => WalletSummary(
    balance: ProfileMockData.walletBalance,
    cards: List.of(ProfileMockData.cards),
    transactions: ProfileMockData.transactions(),
    totalSpent: ProfileMockData.totalSpent,
    addedThisMonth: ProfileMockData.addedThisMonth,
    spentOrderCount: ProfileMockData.spentOrderCount,
  );

  @override
  Future<WalletCard> addCard({
    required String gatewayToken,
    required String brand,
    required String last4,
    required int expiryMonth,
    required int expiryYear,
  }) async => WalletCard(
    id: 'card-${DateTime.now().microsecondsSinceEpoch}',
    brand: brand,
    maskedNumber: '•••• $last4',
    expiry:
        '${expiryMonth.toString().padLeft(2, '0')}/'
        '${expiryYear.toString().padLeft(4, '0').substring(2)}',
  );

  @override
  Future<WalletCard> makeCardDefault(String cardId) async => WalletCard(
    id: cardId,
    brand: 'Debit card',
    maskedNumber: '•••• ••••',
    expiry: '00/00',
    isDefault: true,
  );

  @override
  Future<void> removeCard(String cardId) async {}

  @override
  Future<List<OrderHistoryEntry>> orders() async => ProfileMockData.orders();

  @override
  Future<List<PayoutAccount>> payoutAccounts() async =>
      List.of(_payoutAccounts);

  @override
  Future<PayoutAccount> addPayoutAccount({
    required String kind,
    required String displayName,
    required String accountNumber,
    String? bankName,
  }) async {
    // Masked the way the server masks it, so the offline screens show what the
    // live ones do rather than a raw account number.
    final account = PayoutAccount(
      id: 'payout-${_payoutAccounts.length + 1}',
      label:
          '$displayName ••••'
          '${accountNumber.substring(accountNumber.length - 4)}',
      isDefault: _payoutAccounts.isEmpty,
    );
    _payoutAccounts.add(account);
    return account;
  }
}
