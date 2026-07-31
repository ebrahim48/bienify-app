import '../../domain/entities/auth_session.dart';
import 'user_model.dart';

/// Serialisation layer for [AuthSession].
class AuthSessionModel extends AuthSession {
  const AuthSessionModel({
    required super.accessToken,
    required UserModel super.user,
    super.refreshToken,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String?,
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
