import '../../../../doctor_role/domain/entities/doctor_practice.dart'
    show PayoutAccount;
import '../../../profile/domain/entities/profile.dart';

/// The patient's stored balance, the cards behind it and what has moved
/// through it.
abstract class WalletRepository {
  /// The current balance in major units.
  ///
  /// Read fresh rather than cached: it changes whenever a consultation is paid
  /// for or an order settled, and a stale figure on the payment screen tells
  /// the patient a payment will succeed when it will not.
  Future<double> balance();

  /// Everything the wallet screen prints at once — the balance, the cards, the
  /// ledger and the totals over it.
  Future<WalletSummary> summary();

  /// Tokenised by the gateway before it reaches here; a raw card number must
  /// never cross this boundary.
  Future<WalletCard> addCard({
    required String gatewayToken,
    required String brand,
    required String last4,
    required int expiryMonth,
    required int expiryYear,
  });

  /// Adds money to the wallet by charging a card the patient has already
  /// saved — `POST /wallet/topup`.
  ///
  /// The card is named, not carried: `GET /wallet/cards` strips the gateway
  /// token before it leaves the server, so the app has none to send and the
  /// server looks it up against the id. [idempotencyKey] must stay the same
  /// across retries of one attempt, or a lost response becomes a second
  /// charge.
  Future<WalletTopUp> topUp({
    required int amountMinor,
    required String savedCardId,
    required String idempotencyKey,
  });

  /// Returns the card as the server left it, so a caller can update its list
  /// without re-reading one that another device may have changed underneath.
  Future<WalletCard> makeCardDefault(String cardId);

  Future<void> removeCard(String cardId);

  /// The patient's medicine orders, as My Order History lists them.
  Future<List<OrderHistoryEntry>> orders();

  // ─── Payout destinations ────────────────────────────────────────────────
  //
  // Where money is paid *out* to, as opposed to the cards above, which are how
  // it is taken *in*. Two separate collections on the server, and the Wallet
  // knew only about the first: its "Add Account" button offered Bank Transfer
  // among the methods, ignored whichever was chosen, and filed a card. A
  // courier who added their bank there was then told by the payout sheet to
  // "add a payout account first", because none had ever been created.

  /// `GET /wallet/payout-accounts`.
  Future<List<PayoutAccount>> payoutAccounts();

  /// `POST /wallet/payout-accounts`. [kind] is `bank` or `mobile_money`, which
  /// is the whole enum the server accepts.
  Future<PayoutAccount> addPayoutAccount({
    required String kind,
    required String displayName,
    required String accountNumber,
    String? bankName,
  });
}

/// What a completed top-up left behind.
class WalletTopUp {
  const WalletTopUp({required this.transaction, required this.balanceAfter});

  final WalletTransaction transaction;

  /// The server's own figure, not one the app added up. A balance computed
  /// locally drifts the moment a charge lands from another device.
  final double balanceAfter;
}

/// One read of the wallet screen.
class WalletSummary {
  const WalletSummary({
    required this.balance,
    required this.cards,
    required this.transactions,
    required this.totalSpent,
    required this.addedThisMonth,
    required this.spentOrderCount,
  });

  final double balance;
  final List<WalletCard> cards;
  final List<WalletTransaction> transactions;

  /// Summed from the ledger rather than carried as a field — the server keeps
  /// no lifetime total for a patient, and adding up what is on screen is what
  /// keeps the two agreeing.
  final double totalSpent;
  final double addedThisMonth;
  final int spentOrderCount;
}
