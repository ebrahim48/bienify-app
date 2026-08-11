import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `cash-intents` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class CashIntentsApi {
  CashIntentsApi(this._c);

  final ApiClient _c;

  /// `GET /api/v1/cash-intents`
  Future<dynamic> getCashintents({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.cashIntents, query: query);

  /// `POST /api/v1/cash-intents`
  Future<dynamic> createCashintents({Object? body}) =>
      _c.post(ApiConstants.postCashIntents, body: body);

  /// `GET /api/v1/cash-intents/:id`
  Future<dynamic> getCashintents2({
    required String id,
    Map<String, dynamic>? query,
  }) => _c.get(ApiConstants.cashIntents2(id), query: query);

  /// `POST /api/v1/cash-intents/confirm`
  Future<dynamic> createConfirm({Object? body}) =>
      _c.post(ApiConstants.postCashIntentsConfirm, body: body);
}
