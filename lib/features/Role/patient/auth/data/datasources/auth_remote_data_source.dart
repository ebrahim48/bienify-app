import '../../../../../../core/constants/api_constants.dart';
import '../../../../../../core/network/api_client.dart';
import '../models/auth_session_model.dart';
import '../models/user_model.dart';

/// Network contract for authentication.
///
/// Two implementations ship with the app:
/// * [ApiAuthRemoteDataSource] — talks to the real backend through
///   [ApiClient].
/// * [MockAuthRemoteDataSource] — an in-memory stand-in, so the whole flow is
///   walkable without a server.
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

  /// `POST /auth/register` — a standalone, unauthenticated account creation,
  /// not an update to whatever phone-verified session led here. It answers
  /// with a full session, the same shape [loginWithEmail] does.
  Future<AuthSessionModel> saveCredentials({required Map<String, dynamic> body});

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

/// Live implementation, talking to the Bienify API.
///
/// The interface above was written against an assumed API — snake_case fields,
/// a `verificationId` handed out by an OTP request, and single endpoints for
/// social login and profile completion. The server does none of those things,
/// so this class is where the two shapes are reconciled:
///
/// * OTP is keyed by the phone number itself; there is no server-side
///   verification id, so the phone is carried through in its place.
/// * Social login has one endpoint per provider.
/// * Profile completion is `PATCH /users/me`, not an auth route.
///
/// Password recovery runs by phone, matching the app's screens: the server
/// now accepts either identifier, because an account signed up by phone and
/// given a password afterwards has no email to recover through.
class ApiAuthRemoteDataSource implements AuthRemoteDataSource {
  ApiAuthRemoteDataSource(this._api);

  final ApiClient _api;

  /// The number recovery was started for.
  ///
  /// The screen that submits the new password only carries the code, so the
  /// number is held from the forgot-password step that precedes it.
  String? _pendingResetPhone;

  @override
  Future<Map<String, dynamic>> requestOtp(String phoneNumber) async {
    await _api.post(
      ApiConstants.postAuthOtpRequest,
      body: {'phone': phoneNumber, 'purpose': 'login'},
    );
    // The server keys the code by phone number, so that is what the verify
    // step needs to send back.
    return {'verification_id': phoneNumber};
  }

  @override
  Future<AuthSessionModel> verifyOtp({
    required String verificationId,
    required String code,
  }) async {
    final data = await _api.postMap(
      ApiConstants.postAuthOtpVerify,
      body: {'phone': verificationId, 'code': code, 'purpose': 'login'},
    );
    return AuthSessionModel.fromJson(data);
  }

  @override
  Future<AuthSessionModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final data = await _api.postMap(
      ApiConstants.postAuthLogin,
      body: {'email': email, 'password': password},
    );
    return AuthSessionModel.fromJson(data);
  }

  @override
  Future<AuthSessionModel> socialLogin({
    required String provider,
    required String idToken,
  }) async {
    final path = switch (provider.toLowerCase()) {
      'google' => ApiConstants.postAuthSocialGoogle,
      'apple' => ApiConstants.postAuthSocialApple,
      _ => throw ArgumentError.value(provider, 'provider', 'Unsupported'),
    };
    final data = await _api.postMap(path, body: {'idToken': idToken});
    return AuthSessionModel.fromJson(data);
  }

  @override
  Future<UserModel> saveProfileDetails({
    required String token,
    required Map<String, dynamic> body,
  }) async {
    // The bearer token comes from the client's own session, so `token` is
    // accepted only to satisfy the interface.
    final data = await _api.patch(ApiConstants.updateUsersMe, body: body);
    return UserModel.fromJson((data as Map).cast<String, dynamic>());
  }

  @override
  Future<AuthSessionModel> saveCredentials({
    required Map<String, dynamic> body,
  }) async {
    final data = await _api.postMap(ApiConstants.postAuthRegister, body: body);
    return AuthSessionModel.fromJson(data);
  }

  /// Texts a recovery code to [phoneNumber].
  ///
  /// The server answers the same way whether or not the number has an account,
  /// so this cannot be used to discover who is registered.
  @override
  Future<Map<String, dynamic>> requestPasswordResetOtp(
    String phoneNumber,
  ) async {
    _pendingResetPhone = phoneNumber;
    await _api.post(
      ApiConstants.postAuthPasswordForgot,
      body: {'phone': phoneNumber},
    );
    return {'verification_id': phoneNumber};
  }

  /// Carries the code through to [resetPassword].
  ///
  /// There is deliberately no server call here. A recovery code is single-use:
  /// checking it now would consume it, and the reset that follows would then
  /// be refused with the code the user had just been told was good. The check
  /// happens once, at the reset itself.
  @override
  Future<String> verifyPasswordResetOtp({
    required String verificationId,
    required String code,
  }) async {
    _pendingResetPhone = verificationId;
    return code;
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    final phone = _pendingResetPhone;
    if (phone == null) {
      throw StateError(
        'Password reset needs the number recovery was started for; '
        'call requestPasswordResetOtp first.',
      );
    }
    await _api.post(
      ApiConstants.postAuthPasswordReset,
      body: {'phone': phone, 'code': resetToken, 'newPassword': newPassword},
    );
    _pendingResetPhone = null;
  }

  @override
  Future<void> logout(String token) async {
    final refresh = _api.tokens.refreshToken;
    if (refresh == null) return;
    await _api.post(
      ApiConstants.postAuthLogout,
      body: {'refreshToken': refresh},
    );
    await _api.tokens.clear();
  }
}
