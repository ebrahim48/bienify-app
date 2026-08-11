import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `wallet` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class WalletApi {
  WalletApi(this._c);

  final ApiClient _c;

  /// `GET /api/v1/wallet`
  Future<dynamic> getWallet({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.wallet, query: query);

  /// `GET /api/v1/wallet/cards`
  Future<dynamic> getCards({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.walletCards, query: query);

  /// `POST /api/v1/wallet/cards`
  Future<dynamic> createCards({Object? body}) =>
      _c.post(ApiConstants.postWalletCards, body: body);

  /// `DELETE /api/v1/wallet/cards/:id`
  Future<dynamic> removeCards({required String id, Object? body}) =>
      _c.delete(ApiConstants.deleteWalletCards(id), body: body);

  /// `PATCH /api/v1/wallet/cards/:id/default`
  Future<dynamic> updateCardsdefault({required String id, Object? body}) =>
      _c.patch(ApiConstants.updateWalletCardsDefault(id), body: body);

  /// `GET /api/v1/wallet/earnings`
  Future<dynamic> getEarnings({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.walletEarnings, query: query);

  /// `GET /api/v1/wallet/payout-accounts`
  Future<dynamic> getPayoutaccounts({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.walletPayoutAccounts, query: query);

  /// `POST /api/v1/wallet/payout-accounts`
  Future<dynamic> createPayoutaccounts({Object? body}) =>
      _c.post(ApiConstants.postWalletPayoutAccounts, body: body);

  /// `DELETE /api/v1/wallet/payout-accounts/:id`
  Future<dynamic> removePayoutaccounts({required String id, Object? body}) =>
      _c.delete(ApiConstants.deleteWalletPayoutAccounts(id), body: body);

  /// `PATCH /api/v1/wallet/payout-accounts/:id/default`
  Future<dynamic> updatePayoutaccountsdefault({
    required String id,
    Object? body,
  }) =>
      _c.patch(ApiConstants.updateWalletPayoutAccountsDefault(id), body: body);

  /// `POST /api/v1/wallet/topup`
  Future<dynamic> createTopup({Object? body}) =>
      _c.post(ApiConstants.postWalletTopup, body: body);

  /// `GET /api/v1/wallet/transactions`
  Future<dynamic> getTransactions({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.walletTransactions, query: query);

  /// `GET /api/v1/wallet/withdrawals`
  Future<dynamic> getWithdrawals({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.walletWithdrawals, query: query);

  /// `POST /api/v1/wallet/withdrawals`
  Future<dynamic> createWithdrawals({Object? body}) =>
      _c.post(ApiConstants.postWalletWithdrawals, body: body);
}
