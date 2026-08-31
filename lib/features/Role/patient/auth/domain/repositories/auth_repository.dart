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

  /// Profile-setup step 2 — attaches email/password to the phone account.
  Future<UserEntity> saveCredentials({
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

  /// Changes the password of the account that is already signed in.
  ///
  /// Distinct from [resetPassword], which recovers an account nobody is
  /// holding: this one proves possession with [currentPassword] instead of a
  /// texted code.
  ///
  /// The server revokes every refresh session on success (`logoutAll`, called
  /// from `auth.service.ts:530`), including the caller's — so a successful
  /// change leaves this device holding a dead refresh token, and the caller is
  /// expected to sign out rather than wait for the next refresh to fail.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  // ─── Session ─────────────────────────────────────────────────────────────

  /// The session restored from local storage, or `null` when signed out.
  AuthSession? get currentSession;

  bool get isSignedIn;

  Future<void> logout();
}
