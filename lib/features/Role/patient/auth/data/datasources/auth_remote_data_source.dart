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
/// One mismatch cannot be reconciled here and needs a product decision: the
/// app's recovery screens ask for a phone number and a six-digit code, while
/// the server resets passwords by emailing a token
/// (`POST /auth/password/forgot` takes an email). [requestPasswordResetOtp]
/// therefore expects an email address, and [verifyPasswordResetOtp] has no
/// server call to make — see its comment.
class ApiAuthRemoteDataSource implements AuthRemoteDataSource {
  ApiAuthRemoteDataSource(this._api);

  final ApiClient _api;

  /// The address recovery was started for.
  ///
  /// `POST /auth/password/reset` needs the email alongside the token, but the
  /// screen that submits the new password only has the token — so the address
  /// is held from the forgot-password step that immediately precedes it.
  String? _pendingResetEmail;

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
  Future<UserModel> saveCredentials({
    required String token,
    required Map<String, dynamic> body,
  }) async {
    final data = await _api.postMap(ApiConstants.postAuthRegister, body: body);
    // Registration answers with a session; the caller wants the user out of it.
    final user = data['user'];
    return UserModel.fromJson(
      user is Map ? user.cast<String, dynamic>() : data,
    );
  }

  /// Starts password recovery. Despite the parameter name, the server expects
  /// an **email address** — it mails a reset token rather than texting a code.
  @override
  Future<Map<String, dynamic>> requestPasswordResetOtp(
    String phoneNumber,
  ) async {
    _pendingResetEmail = phoneNumber;
    await _api.post(
      ApiConstants.postAuthPasswordForgot,
      body: {'email': phoneNumber},
    );
    return {'verification_id': phoneNumber};
  }

  /// There is no server-side verify step for password recovery: the token
  /// arrives by email and is submitted directly to [resetPassword]. Returning
  /// the code unchanged keeps the existing screen flow working — it becomes
  /// the `token` that the reset call sends.
  @override
  Future<String> verifyPasswordResetOtp({
    required String verificationId,
    required String code,
  }) async => code;

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    final email = _pendingResetEmail;
    if (email == null) {
      throw StateError(
        'Password reset needs the address recovery was started for; '
        'call requestPasswordResetOtp first.',
      );
    }
    await _api.post(
      ApiConstants.postAuthPasswordReset,
      body: {'email': email, 'token': resetToken, 'newPassword': newPassword},
    );
    _pendingResetEmail = null;
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
