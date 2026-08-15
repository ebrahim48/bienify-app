import '../entities/age_range.dart';
import '../entities/auth_session.dart';
import '../entities/gender.dart';
import '../entities/user_entity.dart';

/// Everything the presentation layer is allowed to ask of authentication.
///
/// Implemented by `AuthRepositoryImpl` in the data layer; controllers only
/// ever see this interface (through use cases), so swapping the backend never
/// touches a screen.
///
/// Methods throw `AppException` subclasses on failure rather than returning
/// error codes — the shared `handleAuthFailure` helper in the controllers
/// turns those into user-facing messages.
abstract class AuthRepository {
  // ─── Phone / OTP ─────────────────────────────────────────────────────────

  /// Sends a one-time code to [phoneNumber] (E.164) and returns the challenge
  /// the OTP screen needs to verify it.
  Future<OtpChallenge> requestOtp({required String phoneNumber});

  /// Confirms [code] against [challenge] and signs the user in.
  Future<AuthSession> verifyOtp({
    required OtpChallenge challenge,
    required String code,
  });

  // ─── Email / social ──────────────────────────────────────────────────────

  Future<AuthSession> loginWithEmail({
    required String email,
    required String password,
  });

  Future<AuthSession> signInWithProvider(SocialProvider provider);

  // ─── Registration ────────────────────────────────────────────────────────

  /// Profile-setup step 1.
  Future<UserEntity> saveProfileDetails({
    required String name,
    required Gender gender,
    required AgeRange ageRange,
  });

  /// Profile-setup step 2 — creates the account.
  ///
  /// The backend has no endpoint that attaches email/password to a
  /// phone-verified session; `POST /auth/register` is a standalone, anonymous
  /// signup that answers with its own session. [name] is required by the
  /// server even though step 1 already collected it — nothing carries it
  /// forward on its own.
  Future<AuthSession> saveCredentials({
    required String name,
    required String email,
    required String password,
  });

  // ─── Password recovery ───────────────────────────────────────────────────

  /// Starts the reset flow by texting a code to [phoneNumber].
  Future<OtpChallenge> requestPasswordResetOtp({required String phoneNumber});

  /// Exchanges a verified reset code for a short-lived reset token.
  Future<String> verifyPasswordResetOtp({
    required OtpChallenge challenge,
    required String code,
  });

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  });

  // ─── Session ─────────────────────────────────────────────────────────────

  /// The session restored from local storage, or `null` when signed out.
  AuthSession? get currentSession;

  bool get isSignedIn;

  Future<void> logout();
}
