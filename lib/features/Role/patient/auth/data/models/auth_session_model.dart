import '../../domain/entities/auth_session.dart';
import 'user_model.dart';

/// Serialisation layer for [AuthSession].
class AuthSessionModel extends AuthSession {
  const AuthSessionModel({
    required super.accessToken,
    required UserModel super.user,
    super.refreshToken,
  });

  /// Reads both the API's shape and this model's own.
  ///
  /// The server answers a sign-in with camelCase `accessToken` /
  /// `refreshToken`; [toJson] writes the snake_case form the local session
  /// cache holds. Reading only the latter is what left every signed-in request
  /// going out with an empty bearer token.
  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      accessToken:
          (json['accessToken'] ?? json['access_token']) as String? ?? '',
      refreshToken:
          (json['refreshToken'] ?? json['refresh_token']) as String?,
      user: UserModel.fromJson(
        (json['user'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'user': (user as UserModel).toJson(),
  };
}
