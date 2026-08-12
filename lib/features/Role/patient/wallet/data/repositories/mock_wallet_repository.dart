import '../../../profile/data/static/profile_mock_data.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../domain/repositories/wallet_repository.dart';

/// A fixed wallet, so the payment and account screens render the same way
/// every run.
class MockWalletRepository implements WalletRepository {
  const MockWalletRepository({this.amount = 45});

  final double amount;

  @override
  Future<double> balance() async => amount;

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
}
