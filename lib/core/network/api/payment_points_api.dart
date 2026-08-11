import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `payment-points` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class PaymentPointsApi {
  PaymentPointsApi(this._c);

  final ApiClient _c;

  /// `GET /api/v1/payment-points`
  Future<dynamic> getPaymentpoints({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.paymentPoints, query: query);
}
