import '../../domain/entities/auth_session.dart';

/// Which journey the shared phone / OTP screens are serving.
///
/// The same two screens appear twice in the designs — once while signing up
/// ("Get OTP" → **Next**) and once while resetting a password ("Enter OTP" →
/// **Verify Now**). This enum is what tells them apart, so neither screen is
/// duplicated.
enum AuthFlow {
  signUp,
  passwordReset;

  bool get isSignUp => this == AuthFlow.signUp;
}

/// Arguments handed to the OTP screen.
class OtpArguments {
  const OtpArguments({required this.challenge, required this.flow});

  final OtpChallenge challenge;
  final AuthFlow flow;
}

/// Arguments handed to the "Enter New Password" screen.
class NewPasswordArguments {
  const NewPasswordArguments({required this.resetToken});

  final String resetToken;
}
