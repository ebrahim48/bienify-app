import '../../domain/repositories/wallet_repository.dart';

/// A fixed balance, so the payment screen renders the same way every run.
class MockWalletRepository implements WalletRepository {
  const MockWalletRepository({this.amount = 45});

  final double amount;

  @override
  Future<double> balance() async => amount;
}
