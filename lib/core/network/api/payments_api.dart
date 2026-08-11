import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `payments` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class PaymentsApi {
  PaymentsApi(this._c);

  final ApiClient _c;

  /// `POST /api/v1/payments/appointments/:id/pay`
  Future<dynamic> createAppointmentspay({required String id, Object? body}) =>
      _c.post(ApiConstants.postPaymentsAppointmentsPay(id), body: body);

  /// `POST /api/v1/payments/appointments/:id/refund`
  Future<dynamic> createAppointmentsrefund({
    required String id,
    Object? body,
  }) => _c.post(ApiConstants.postPaymentsAppointmentsRefund(id), body: body);
}
