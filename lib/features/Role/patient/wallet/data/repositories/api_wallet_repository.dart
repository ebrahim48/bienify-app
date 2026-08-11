import '../../../../../../core/constants/api_constants.dart';
import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/network/mappers.dart';
import '../../domain/repositories/wallet_repository.dart';

/// The wallet, served by the API.
class ApiWalletRepository implements WalletRepository {
  const ApiWalletRepository(this._api);

  final ApiClient _api;

  @override
  Future<double> balance() async {
    final data = await _api.getMap(ApiConstants.wallet);
    return Api.majorUnits(data['balanceMinor']);
  }
}
