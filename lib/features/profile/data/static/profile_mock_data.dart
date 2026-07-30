import '../../../../core/constants/app_assets.dart';
import '../../domain/entities/profile.dart';

/// Sample account data behind the profile section.
///
/// Static by design — this feature is UI-first, so there is no repository or
/// API here; the shapes are what a future endpoint will fill in.
class ProfileMockData {
  ProfileMockData._();

  static const PatientProfile patient = PatientProfile(
    name: 'Mohammod Jakuan',
    maskedPhone: '+880 189* ****',
    photoAsset: AppAssets.doctorPlaceholder,
  );

  /// Empty on purpose: the wallet design opens with no account added.
  static const List<WalletCard> cards = <WalletCard>[];

  /// The design shows a zero balance against real spend history.
  static const double walletBalance = 0;
  static const double totalSpent = 73;
  static const int spentOrderCount = 3;
  static const double addedThisMonth = 56;

  static List<WalletTransaction> transactions() => [
    WalletTransaction(
      id: 'tx-1',
      title: 'Order #RX8841',
      occurredOn: DateTime(2026, 7, 10),
      amount: 32.40,
      kind: TransactionKind.debit,
    ),
    WalletTransaction(
      id: 'tx-2',
      title: 'Wallet top-up',
      occurredOn: DateTime(2026, 7, 8),
      amount: 50,
      kind: TransactionKind.credit,
    ),
    WalletTransaction(
      id: 'tx-3',
      title: 'Order #RX8820',
      occurredOn: DateTime(2026, 6, 28),
      amount: 18.50,
      kind: TransactionKind.debit,
    ),
    WalletTransaction(
      id: 'tx-4',
      title: 'Refund — cancelled order',
      occurredOn: DateTime(2026, 6, 20),
      amount: 6,
      kind: TransactionKind.credit,
    ),
    WalletTransaction(
      id: 'tx-5',
      title: 'Order #RX8799',
      occurredOn: DateTime(2026, 6, 14),
      amount: 22.10,
      kind: TransactionKind.debit,
    ),
  ];

  /// The four rows the design lists — one per state, so every status pill and
  /// every filter chip has something to show.
  static List<OrderHistoryEntry> orders() => [
    OrderHistoryEntry(
      id: 'order-1',
      reference: '#RX8820',
      storeName: 'MediQuick Pharmacy',
      placedOn: DateTime(2026, 6, 28, 15, 45),
      itemCount: 5,
      total: 74.89,
      state: OrderState.delivered,
    ),
    OrderHistoryEntry(
      id: 'order-2',
      reference: '#RX8799',
      storeName: 'HealthPlus Pharmacy',
      placedOn: DateTime(2026, 6, 14, 11, 20),
      itemCount: 3,
      total: 36.70,
      state: OrderState.delivered,
    ),
    OrderHistoryEntry(
      id: 'order-3',
      reference: '#RX8799',
      storeName: 'HealthPlus Pharmacy',
      placedOn: DateTime(2026, 6, 14, 9, 5),
      itemCount: 3,
      total: 36.70,
      state: OrderState.inProgress,
    ),
    OrderHistoryEntry(
      id: 'order-4',
      reference: '#RX8799',
      storeName: 'HealthPlus Pharmacy',
      placedOn: DateTime(2026, 6, 14, 8, 30),
      itemCount: 3,
      total: 36.70,
      state: OrderState.cancelled,
    ),
  ];
}
