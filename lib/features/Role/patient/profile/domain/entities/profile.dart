/// Shapes behind the account section.
///
/// **Names only, by design.** This feature is UI-first: there is no
/// repository, use case or data source under it, and nothing calls an API.
/// The controllers read `ProfileMockData` and these types describe what a
/// future endpoint will fill in.
library;

/// The signed-in patient, as shown on the profile card.
class PatientProfile {
  const PatientProfile({
    required this.name,
    required this.maskedPhone,
    this.photoUrl,
    this.photoAsset,
  });

  final String name;

  /// Partially hidden, the way the design shows it: `+880 189* ****`.
  final String maskedPhone;

  final String? photoUrl;
  final String? photoAsset;
}

/// Which partner programme the applicant is signing up for.
enum PartnerRole { pharmacyOwner, rider }

/// A saved card or balance in the wallet.
class WalletCard {
  const WalletCard({
    required this.id,
    required this.brand,
    required this.maskedNumber,
    required this.expiry,
    this.isDefault = false,
  });

  final String id;
  final String brand;
  final String maskedNumber;
  final String expiry;
  final bool isDefault;
}

/// Whether an order in the history is still moving or finished.
enum OrderState { delivered, cancelled, inProgress }

/// One row on My Order History.
class OrderHistoryEntry {
  const OrderHistoryEntry({
    required this.id,
    required this.reference,
    required this.storeName,
    required this.placedOn,
    required this.itemCount,
    required this.total,
    required this.state,
    this.pharmacyId = '',
    this.storeAddress = '',
    this.storeCity = '',
    this.quantitiesByMedicineId = const {},
  });

  final String id;
  final String reference;
  final String storeName;

  /// The shop that filled it, so a review can be read for and written against
  /// the right one. The review screen showed the first demo store to everybody
  /// without it.
  final String pharmacyId;

  /// Where the shop is, from the same row.
  final String storeAddress;
  final String storeCity;
  final DateTime placedOn;
  final int itemCount;

  /// What was actually ordered, so it can be ordered again.
  ///
  /// Reorder opened an empty cart: the row knew how many items there were and
  /// nothing about which. The payload has always carried them.
  final Map<String, int> quantitiesByMedicineId;
  final double total;
  final OrderState state;

  String get totalLabel => '\$${total.toStringAsFixed(2)}';
}

/// Which chip is active above the order list. `all` matches every state.
enum OrderFilter { all, delivered, pending, cancelled }

/// Whether a wallet movement added money or took it out.
enum TransactionKind { debit, credit }

/// One row of the wallet's transaction history.
class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.title,
    required this.occurredOn,
    required this.amount,
    required this.kind,
  });

  final String id;
  final String title;
  final DateTime occurredOn;

  /// Always positive; [kind] carries the direction.
  final double amount;

  final TransactionKind kind;

  /// Debits print bare (`-32.40`), credits with a currency sign (`+$50.00`) —
  /// which is how the design distinguishes them at a glance.
  String get amountLabel => switch (kind) {
    TransactionKind.debit => '-${amount.toStringAsFixed(2)}',
    TransactionKind.credit => '+\$${amount.toStringAsFixed(2)}',
  };
}

/// Which legal document a `LegalScreen` is showing.
enum LegalDocument { aboutUs, terms, privacy }
