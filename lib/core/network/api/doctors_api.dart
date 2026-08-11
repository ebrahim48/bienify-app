import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `doctors` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class DoctorsApi {
  DoctorsApi(this._c);

  final ApiClient _c;

  /// `GET /api/v1/doctors`
  Future<dynamic> getDoctors({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.doctors, query: query);

  /// `GET /api/v1/doctors/:id`
  Future<dynamic> getDoctors2({
    required String id,
    Map<String, dynamic>? query,
  }) => _c.get(ApiConstants.doctors2(id), query: query);

  /// `GET /api/v1/doctors/me`
  Future<dynamic> getMe({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.doctorsMe, query: query);

  /// `POST /api/v1/doctors/me`
  Future<dynamic> createMe({Object? body}) =>
      _c.post(ApiConstants.postDoctorsMe, body: body);

  /// `PUT /api/v1/doctors/me/availability`
  Future<dynamic> replaceMeavailability({Object? body}) =>
      _c.put(ApiConstants.putDoctorsMeAvailability, body: body);

  /// `POST /api/v1/doctors/me/availability/exceptions`
  Future<dynamic> createMeavailabilityexceptions({Object? body}) =>
      _c.post(ApiConstants.postDoctorsMeAvailabilityExceptions, body: body);

  /// `POST /api/v1/doctors/me/credentials`
  Future<dynamic> createMecredentials({Object? body}) =>
      _c.post(ApiConstants.postDoctorsMeCredentials, body: body);

  /// `GET /api/v1/doctors/me/stats`
  Future<dynamic> getMestats({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.doctorsMeStats, query: query);
}
