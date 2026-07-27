import 'user_entity.dart';

/// The result of any successful authentication: who signed in, and the
/// credentials needed to talk to the API on their behalf.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.user,
    this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;
  final UserEntity user;

  /// True when the user still has to finish the two profile-setup steps.
  bool get requiresProfileSetup => !user.isProfileComplete;

  AuthSession copyWith({
    String? accessToken,
    String? refreshToken,
    UserEntity? user,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      user: user ?? this.user,
    );
  }
}

/// A pending phone verification — returned when an OTP has been sent and
/// carried into the OTP screen so it knows what it is confirming.
class OtpChallenge {
  const OtpChallenge({
    required this.verificationId,
    required this.phoneNumber,
    this.resendCooldown = const Duration(seconds: 60),
  });

  /// Opaque handle the backend uses to match the code to the request.
  final String verificationId;

  /// Number the code was sent to, shown back to the user.
  final String phoneNumber;

  final Duration resendCooldown;
}

/// Third-party identity providers offered on the onboarding panel.
enum SocialProvider { google, apple }
