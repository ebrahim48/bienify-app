import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `consultations` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class ConsultationsApi {
  ConsultationsApi(this._c);

  final ApiClient _c;

  /// `POST /api/v1/consultations/:id/follow-up`
  Future<dynamic> createFollowup({required String id, Object? body}) =>
      _c.post(ApiConstants.postConsultationsFollowUp(id), body: body);

  /// `POST /api/v1/consultations/:id/join`
  Future<dynamic> createJoin({required String id, Object? body}) =>
      _c.post(ApiConstants.postConsultationsJoin(id), body: body);

  /// `GET /api/v1/consultations/:id/messages`
  Future<dynamic> getMessages({
    required String id,
    Map<String, dynamic>? query,
  }) => _c.get(ApiConstants.consultationsMessages(id), query: query);

  /// `POST /api/v1/consultations/:id/messages`
  Future<dynamic> createMessages({required String id, Object? body}) =>
      _c.post(ApiConstants.postConsultationsMessages(id), body: body);

  /// `PATCH /api/v1/consultations/:id/notes`
  Future<dynamic> updateNotes({required String id, Object? body}) =>
      _c.patch(ApiConstants.updateConsultationsNotes(id), body: body);

  /// `POST /api/v1/consultations/:id/prescriptions`
  Future<dynamic> createPrescriptions({required String id, Object? body}) =>
      _c.post(ApiConstants.postConsultationsPrescriptions(id), body: body);

  /// `GET /api/v1/consultations/threads`
  Future<dynamic> getThreads({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.consultationsThreads, query: query);
}
