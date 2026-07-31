import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Sends a verification code to a phone number.
///
/// Use cases are grouped one file per flow (phone, email, registration,
/// recovery) rather than one file per class — each is a thin, single-method
/// object and the flow is easier to read when its steps sit together.
class RequestOtp {
  const RequestOtp(this._repository);

  final AuthRepository _repository;

  Future<OtpChallenge> call(String phoneNumber) =>
      _repository.requestOtp(phoneNumber: phoneNumber);
}

/// Confirms a verification code and returns the resulting session.
class VerifyOtp {
  const VerifyOtp(this._repository);

  final AuthRepository _repository;

  Future<AuthSession> call({
    required OtpChallenge challenge,
    required String code,
  }) => _repository.verifyOtp(challenge: challenge, code: code);
}
