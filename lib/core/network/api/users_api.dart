import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `users` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class UsersApi {
  UsersApi(this._c);

  final ApiClient _c;

  /// `GET /api/v1/users/me`
  Future<dynamic> getMe({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.usersMe, query: query);

  /// `PATCH /api/v1/users/me`
  Future<dynamic> updateMe({Object? body}) =>
      _c.patch(ApiConstants.updateUsersMe, body: body);

  /// `DELETE /api/v1/users/me`
  Future<dynamic> removeMe({Object? body}) =>
      _c.delete(ApiConstants.deleteUsersMe, body: body);

  /// `POST /api/v1/users/me/avatar/confirm`
  Future<dynamic> createMeavatarconfirm({Object? body}) =>
      _c.post(ApiConstants.postUsersMeAvatarConfirm, body: body);

  /// `POST /api/v1/users/me/avatar/upload-url`
  Future<dynamic> createMeavataruploadurl({Object? body}) =>
      _c.post(ApiConstants.postUsersMeAvatarUploadUrl, body: body);

  /// `POST /api/v1/users/me/address/door-image/upload-url`
  Future<dynamic> createMeaddressdoorimageuploadurl({Object? body}) =>
      _c.post(ApiConstants.postUsersMeDoorImageUploadUrl, body: body);
}
