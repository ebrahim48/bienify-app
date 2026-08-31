import '../../../../../../core/exceptions/app_exceptions.dart';
import '../models/auth_session_model.dart';
import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

/// In-memory stand-in for the auth API.
///
/// It lets the complete sign-up, login and password-reset journeys be walked
/// (and demoed) before the backend exists. Swap it for
/// [ApiAuthRemoteDataSource] in `DependencyInjection` — no other file changes.
///
/// Behaviour worth knowing while testing:
/// * any 6-digit code is accepted **except** `000000`, which fails, so the
///   error path is reachable;
/// * `wrong@bienify.app` always fails to sign in;
/// * `wrongpassword` is refused as a current password, so Change Password's
///   failure path is walkable offline;
/// * every call is delayed to exercise the loading states.
class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  static const Duration _latency = Duration(milliseconds: 900);
  static const String _rejectedCode = '000000';
  static const String _rejectedEmail = 'wrong@bienify.app';
  static const String _rejectedPassword = 'wrongpassword';

  UserModel _user = const UserModel(id: 'mock-user-1');

  Future<T> _delayed<T>(T Function() build) async {
    await Future<void>.delayed(_latency);
    return build();
  }

  AuthSessionModel get _session => AuthSessionModel(
    accessToken: 'mock-access-token',
    refreshToken: 'mock-refresh-token',
    user: _user,
  );

  @override
  Future<Map<String, dynamic>> requestOtp(String phoneNumber) {
    _user = UserModel(
      id: _user.id,
      name: _user.name,
      email: _user.email,
      phoneNumber: phoneNumber,
      gender: _user.gender,
      ageRange: _user.ageRange,
      isProfileComplete: _user.isProfileComplete,
    );
    return _delayed(
      () => {
        'verification_id': 'mock-verification-id',
        'phone_number': phoneNumber,
        'resend_cooldown_seconds': 60,
      },
    );
  }

  @override
  Future<AuthSessionModel> verifyOtp({
    required String verificationId,
    required String code,
  }) {
    return _delayed(() {
      if (code == _rejectedCode) {
        throw ServerException('That code is not valid', 401);
      }
      return _session;
    });
  }

  @override
  Future<AuthSessionModel> loginWithEmail({
    required String email,
    required String password,
  }) {
    return _delayed(() {
      if (email.toLowerCase() == _rejectedEmail) {
        throw ServerException('Incorrect email or password', 401);
      }
      _user = UserModel(
        id: _user.id,
        name: _user.name ?? 'Bienify User',
        email: email,
        phoneNumber: _user.phoneNumber,
        gender: _user.gender,
        ageRange: _user.ageRange,
        isProfileComplete: true,
      );
      return _session;
    });
  }

  @override
  Future<AuthSessionModel> socialLogin({
    required String provider,
    required String idToken,
  }) {
    return _delayed(() {
      _user = UserModel(
        id: _user.id,
        name: 'Bienify User',
        email: 'user@$provider.com',
        phoneNumber: _user.phoneNumber,
        isProfileComplete: true,
      );
      return _session;
    });
  }

  @override
  Future<UserModel> saveProfileDetails({
    required String token,
    required Map<String, dynamic> body,
  }) {
    return _delayed(() {
      _user = UserModel(
        id: _user.id,
        name: body['name'] as String?,
        email: _user.email,
        phoneNumber: _user.phoneNumber,
        gender: _user.gender,
        ageRange: _user.ageRange,
        isProfileComplete: false,
      );
      return UserModel.fromJson({
        ..._user.toJson(),
        'gender': body['gender'],
        'age_range': body['age_range'],
      });
    });
  }

  @override
  Future<UserModel> saveCredentials({
    required String token,
    required Map<String, dynamic> body,
  }) {
    return _delayed(() {
      _user = UserModel.fromJson({
        ..._user.toJson(),
        'email': body['email'],
        'is_profile_complete': true,
      });
      return _user;
    });
  }

  @override
  Future<Map<String, dynamic>> requestPasswordResetOtp(String phoneNumber) =>
      requestOtp(phoneNumber);

  @override
  Future<String> verifyPasswordResetOtp({
    required String verificationId,
    required String code,
  }) {
    return _delayed(() {
      if (code == _rejectedCode) {
        throw ServerException('That code is not valid', 401);
      }
      return 'mock-reset-token';
    });
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) => _delayed(() {});

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _delayed(() {
    // The live server answers 401 when the current password is wrong, so the
    // stand-in has to reach that branch too — a mock that always succeeds
    // documents a screen that cannot fail.
    if (currentPassword == _rejectedPassword) {
      throw UnauthorizedException('Current password is incorrect');
    }
  });

  @override
  Future<void> logout(String token) => _delayed(() {
    _user = const UserModel(id: 'mock-user-1');
  });
}
