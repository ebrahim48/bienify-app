import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `auth` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class AuthApi {
  AuthApi(this._c);

  final ApiClient _c;

  /// `POST /api/v1/auth/login`
  Future<dynamic> createLogin({Object? body}) =>
      _c.post(ApiConstants.postAuthLogin, body: body);

  /// `POST /api/v1/auth/logout`
  Future<dynamic> createLogout({Object? body}) =>
      _c.post(ApiConstants.postAuthLogout, body: body);

  /// `POST /api/v1/auth/logout-all`
  Future<dynamic> createLogoutall({Object? body}) =>
      _c.post(ApiConstants.postAuthLogoutAll, body: body);

  /// `POST /api/v1/auth/otp/request`
  Future<dynamic> createOtprequest({Object? body}) =>
      _c.post(ApiConstants.postAuthOtpRequest, body: body);

  /// `POST /api/v1/auth/otp/verify`
  Future<dynamic> createOtpverify({Object? body}) =>
      _c.post(ApiConstants.postAuthOtpVerify, body: body);

  /// `POST /api/v1/auth/password/change`
  Future<dynamic> createPasswordchange({Object? body}) =>
      _c.post(ApiConstants.postAuthPasswordChange, body: body);

  /// `POST /api/v1/auth/password/forgot`
  Future<dynamic> createPasswordforgot({Object? body}) =>
      _c.post(ApiConstants.postAuthPasswordForgot, body: body);

  /// `POST /api/v1/auth/password/reset`
  Future<dynamic> createPasswordreset({Object? body}) =>
      _c.post(ApiConstants.postAuthPasswordReset, body: body);

  /// `POST /api/v1/auth/credentials`
  Future<dynamic> createCredentials({Object? body}) =>
      _c.post(ApiConstants.postAuthCredentials, body: body);

  /// `POST /api/v1/auth/refresh`
  Future<dynamic> createRefresh({Object? body}) =>
      _c.post(ApiConstants.postAuthRefresh, body: body);

  /// `POST /api/v1/auth/register`
  Future<dynamic> createRegister({Object? body}) =>
      _c.post(ApiConstants.postAuthRegister, body: body);

  /// `POST /api/v1/auth/social/apple`
  Future<dynamic> createSocialapple({Object? body}) =>
      _c.post(ApiConstants.postAuthSocialApple, body: body);

  /// `POST /api/v1/auth/social/google`
  Future<dynamic> createSocialgoogle({Object? body}) =>
      _c.post(ApiConstants.postAuthSocialGoogle, body: body);
}
