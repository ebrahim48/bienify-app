import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Step 1 of "Forgot password" — text a code to the account's phone number.
class RequestPasswordResetOtp {
  const RequestPasswordResetOtp(this._repository);

  final AuthRepository _repository;

  Future<OtpChallenge> call(String phoneNumber) =>
      _repository.requestPasswordResetOtp(phoneNumber: phoneNumber);
}

/// Step 2 — confirm the code and receive a short-lived reset token.
class VerifyPasswordResetOtp {
  const VerifyPasswordResetOtp(this._repository);

  final AuthRepository _repository;

  Future<String> call({
    required OtpChallenge challenge,
    required String code,
  }) => _repository.verifyPasswordResetOtp(challenge: challenge, code: code);
}

/// Step 3 — exchange the reset token for a new password.
class ResetPassword {
  const ResetPassword(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String resetToken,
    required String newPassword,
  }) => _repository.resetPassword(
    resetToken: resetToken,
    newPassword: newPassword,
  );
}
