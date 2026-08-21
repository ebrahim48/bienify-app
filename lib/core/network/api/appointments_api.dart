import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `appointments` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class AppointmentsApi {
  AppointmentsApi(this._c);

  final ApiClient _c;

  /// `GET /api/v1/appointments`
  Future<dynamic> getAppointments({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.appointments, query: query);

  /// `POST /api/v1/appointments`
  Future<dynamic> createAppointments({Object? body}) =>
      _c.post(ApiConstants.postAppointments, body: body);

  /// `GET /api/v1/appointments/:id`
  Future<dynamic> getAppointments2({
    required String id,
    Map<String, dynamic>? query,
  }) => _c.get(ApiConstants.appointments2(id), query: query);

  /// `POST /api/v1/appointments/:id/cancel`
  Future<dynamic> createCancel({required String id, Object? body}) =>
      _c.post(ApiConstants.postAppointmentsCancel(id), body: body);

  /// `POST /api/v1/appointments/:id/refund`
  Future<dynamic> createRefund({required String id, Object? body}) =>
      _c.post(ApiConstants.postAppointmentsRefund(id), body: body);

  /// `POST /api/v1/appointments/:id/request-refund`
  Future<dynamic> createRequestRefund({required String id, Object? body}) =>
      _c.post(ApiConstants.postAppointmentsRequestRefund(id), body: body);

  /// `POST /api/v1/appointments/:id/reschedule`
  Future<dynamic> createReschedule({required String id, Object? body}) =>
      _c.post(ApiConstants.postAppointmentsReschedule(id), body: body);

  /// `POST /api/v1/appointments/:id/complete`
  Future<dynamic> createComplete({required String id, Object? body}) =>
      _c.post(ApiConstants.postAppointmentsComplete(id), body: body);

  /// `POST /api/v1/appointments/:id/no-show`
  Future<dynamic> createNoshow({required String id, Object? body}) =>
      _c.post(ApiConstants.postAppointmentsNoShow(id), body: body);

  /// `POST /api/v1/appointments/:id/start`
  Future<dynamic> createStart({required String id, Object? body}) =>
      _c.post(ApiConstants.postAppointmentsStart(id), body: body);

  /// `GET /api/v1/appointments/slots`
  Future<dynamic> getSlots({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.appointmentsSlots, query: query);
}
