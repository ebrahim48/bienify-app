import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../models/auth_session_model.dart';
import '../models/user_model.dart';

/// Network contract for authentication.
///
/// Two implementations ship with the app:
/// * [ApiAuthRemoteDataSource] — talks to the real backend through
///   `ApiService`.
/// * [MockAuthRemoteDataSource] — an in-memory stand-in used until the API is
///   live, so the whole flow is walkable end to end.
///
/// `DependencyInjection` decides which one is bound; nothing else in the app
/// knows the difference.
abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> requestOtp(String phoneNumber);

  Future<AuthSessionModel> verifyOtp({
    required String verificationId,
    required String code,
  });

  Future<AuthSessionModel> loginWithEmail({
    required String email,
    required String password,
  });

  Future<AuthSessionModel> socialLogin({
    required String provider,
    required String idToken,
  });

  Future<UserModel> saveProfileDetails({
    required String token,
    required Map<String, dynamic> body,
  });

  Future<UserModel> saveCredentials({
    required String token,
    required Map<String, dynamic> body,
  });

  Future<Map<String, dynamic>> requestPasswordResetOtp(String phoneNumber);

  Future<String> verifyPasswordResetOtp({
    required String verificationId,
    required String code,
  });

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  });

  Future<void> logout(String token);
}

/// Live implementation backed by `ApiService` / Dio.
class ApiAuthRemoteDataSource implements AuthRemoteDataSource {
  const ApiAuthRemoteDataSource(this._api);

  final ApiService _api;

  Map<String, dynamic> _body(dynamic data) =>
      (data as Map?)?.cast<String, dynamic>() ?? const {};

  @override
  Future<Map<String, dynamic>> requestOtp(String phoneNumber) async {
    final response = await _api.post(
      ApiConstants.requestOtp,
      data: {'phone_number': phoneNumber},
    );
    return _body(response.data);
  }

  @override
  Future<AuthSessionModel> verifyOtp({
    required String verificationId,
    required String code,
  }) async {
    final response = await _api.post(
      ApiConstants.verifyOtp,
      data: {'verification_id': verificationId, 'code': code},
    );
    return AuthSessionModel.fromJson(_body(response.data));
  }

  @override
  Future<AuthSessionModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      ApiConstants.loginWithEmail,
      data: {'email': email, 'password': password},
    );
    return AuthSessionModel.fromJson(_body(response.data));
  }

  @override
  Future<AuthSessionModel> socialLogin({
    required String provider,
    required String idToken,
  }) async {
    final response = await _api.post(
      ApiConstants.socialLogin,
      data: {'provider': provider, 'id_token': idToken},
    );
    return AuthSessionModel.fromJson(_body(response.data));
  }

  @override
  Future<UserModel> saveProfileDetails({
    required String token,
    required Map<String, dynamic> body,
  }) async {
    final response = await _api.post(
      ApiConstants.completeProfile,
      data: body,
      options: Options(headers: ApiConstants.authorized(token)),
    );
    return UserModel.fromJson(_body(response.data));
  }

  @override
  Future<UserModel> saveCredentials({
    required String token,
    required Map<String, dynamic> body,
  }) async {
    final response = await _api.post(
      ApiConstants.registerCredentials,
      data: body,
      options: Options(headers: ApiConstants.authorized(token)),
    );
    return UserModel.fromJson(_body(response.data));
  }

  @override
  Future<Map<String, dynamic>> requestPasswordResetOtp(
    String phoneNumber,
  ) async {
    final response = await _api.post(
      ApiConstants.forgotPassword,
      data: {'phone_number': phoneNumber},
    );
    return _body(response.data);
  }

  @override
  Future<String> verifyPasswordResetOtp({
    required String verificationId,
    required String code,
  }) async {
    final response = await _api.post(
      ApiConstants.verifyOtp,
      data: {
        'verification_id': verificationId,
        'code': code,
        'purpose': 'password_reset',
      },
    );
    return _body(response.data)['reset_token'] as String? ?? '';
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    await _api.post(
      ApiConstants.resetPassword,
      data: {'reset_token': resetToken, 'password': newPassword},
    );
  }

  @override
  Future<void> logout(String token) async {
    await _api.post(
      ApiConstants.logout,
      options: Options(headers: ApiConstants.authorized(token)),
    );
  }
}
