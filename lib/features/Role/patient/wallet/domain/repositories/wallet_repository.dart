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

  /// Returns the card as the server left it, so a caller can update its list
  /// without re-reading one that another device may have changed underneath.
  Future<WalletCard> makeCardDefault(String cardId);

  Future<void> removeCard(String cardId);

  /// The patient's medicine orders, as My Order History lists them.
  Future<List<OrderHistoryEntry>> orders();
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
