import '../../../../../../core/constants/api_constants.dart';
import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/network/mappers.dart';
import '../../../../doctor_role/domain/entities/doctor_practice.dart'
    show PayoutAccount;
import '../../../profile/domain/entities/profile.dart';
import '../../domain/repositories/wallet_repository.dart';

/// The wallet, served by the API.
class ApiWalletRepository implements WalletRepository {
  const ApiWalletRepository(this._api);

  final ApiClient _api;

  /// The server caps a page at 100, and neither the ledger nor the order
  /// history pages in the design.
  static const int _pageSize = 100;

  @override
  Future<double> balance() async {
    final data = await _api.getMap(ApiConstants.wallet);
    return Api.majorUnits(data['balanceMinor']);
  }

  @override
  Future<WalletSummary> summary() async {
    final results = await Future.wait([
      _api.getMap(ApiConstants.wallet),
      _api.get(ApiConstants.walletTransactions, query: {'limit': _pageSize}),
      _api.get(ApiConstants.walletCards),
    ]);

    final wallet = Api.map(results[0]);
    final ledger = ApiClient.listFrom(results[1]);
    final cards = ApiClient.listFrom(results[2]);

    final debits = ledger.where((t) => Api.str(t['direction']) == 'debit');
    final now = DateTime.now();
    final credits = ledger.where(
      (t) =>
          Api.str(t['direction']) == 'credit' &&
          Api.date(t['createdAt']).year == now.year &&
          Api.date(t['createdAt']).month == now.month,
    );

    return WalletSummary(
      balance: Api.majorUnits(wallet['balanceMinor']),
      cards: cards.map(walletCardFrom).toList(),
      transactions: ledger.map(walletTransactionFrom).toList(),
      // The server keeps no lifetime totals for a patient, so both are summed
      // from the ledger the screen is already showing — which is also what
      // keeps the figure and the rows under it agreeing.
      totalSpent: debits.fold(
        0,
        (n, t) => n + Api.majorUnits(t['amountMinor']),
      ),
      addedThisMonth: credits.fold(
        0,
        (n, t) => n + Api.majorUnits(t['amountMinor']),
      ),
      spentOrderCount: debits.length,
    );
  }

  @override
  Future<WalletTopUp> topUp({
    required int amountMinor,
    required String savedCardId,
    required String idempotencyKey,
  }) async {
    final data = await _api.postMap(
      ApiConstants.postWalletTopup,
      body: {
        'amountMinor': amountMinor,
        'savedCardId': savedCardId,
        'idempotencyKey': idempotencyKey,
      },
    );
    return WalletTopUp(
      transaction: walletTransactionFrom(data),
      // The response carries the balance the ledger row left behind, so the
      // screen shows the server's figure rather than one it worked out.
      balanceAfter: Api.majorUnits(data['balanceAfterMinor']),
    );
  }

  @override
  Future<WalletCard> addCard({
    required String gatewayToken,
    required String brand,
    required String last4,
    required int expiryMonth,
    required int expiryYear,
  }) async {
    final data = await _api.postMap(
      ApiConstants.postWalletCards,
      body: {
        'gatewayToken': gatewayToken,
        'brand': brand,
        'last4': last4,
        'expiryMonth': expiryMonth,
        'expiryYear': expiryYear,
      },
    );
    return walletCardFrom(data);
  }

  @override
  Future<WalletCard> makeCardDefault(String cardId) async {
    final data = await _api.patch(
      ApiConstants.updateWalletCardsDefault(cardId),
    );
    return walletCardFrom(Api.map(data));
  }

  @override
  Future<void> removeCard(String cardId) async {
    await _api.delete(ApiConstants.deleteWalletCards(cardId));
  }

  @override
  Future<List<OrderHistoryEntry>> orders() async {
    final rows = await _api.getList(
      ApiConstants.medicineOrders,
      query: {'limit': _pageSize},
    );
    return rows.map(orderHistoryEntryFrom).toList();
  }

  @override
  Future<List<PayoutAccount>> payoutAccounts() async {
    final rows = await _api.getList(ApiConstants.walletPayoutAccounts);
    return rows.map(payoutAccountFrom).toList();
  }

  @override
  Future<PayoutAccount> addPayoutAccount({
    required String kind,
    required String displayName,
    required String accountNumber,
    String? bankName,
  }) async {
    final data = await _api.postMap(
      ApiConstants.postWalletPayoutAccounts,
      body: {
        'kind': kind,
        'displayName': displayName,
        'accountNumber': accountNumber,
        // Only a bank account has one, and the server rejects an empty string
        // where it expects a name or nothing at all.
        if (bankName != null && bankName.isNotEmpty) 'bankName': bankName,
      },
    );
    return payoutAccountFrom(data);
  }
}
