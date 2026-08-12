import '../../../../../../core/constants/api_constants.dart';
import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/network/mappers.dart';
import '../../domain/entities/cash_payment.dart';
import '../../domain/repositories/cash_payment_repository.dart';

/// Cash payment, served by the API.
class ApiCashPaymentRepository implements CashPaymentRepository {
  const ApiCashPaymentRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<PaymentPoint>> points() async {
    final rows = await _api.getList(
      ApiConstants.paymentPoints,
      query: {'limit': 100},
    );
    return rows.map(paymentPointFrom).toList();
  }

  @override
  Future<PaymentCode> issueCode({
    required String paymentPointId,
    required double amount,
  }) async {
    final data = await _api.postMap(
      ApiConstants.postCashIntents,
      body: {
        'paymentPointId': paymentPointId,
        'amountMinor': (amount * 100).round(),
      },
    );
    return paymentCodeFrom(data);
  }

  @override
  Future<CashIntentState> refresh(String reference) async {
    // The list is the patient's own intents, so the code can be found in it
    // without an id — which is all the pending screen has to go on.
    final rows = await _api.getList(ApiConstants.cashIntents);
    final match = rows.firstWhere(
      (row) => Api.str(row['reference']) == reference.replaceAll('#', ''),
      orElse: () => const {},
    );
    return cashIntentStateFrom(Api.str(match['status'], 'pending'));
  }
}
