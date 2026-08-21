import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/network/token_store.dart';
import '../../domain/entities/age_range.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/gender.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_session_model.dart';
import '../models/user_model.dart';

/// Coordinates the remote API and local persistence behind
/// [AuthRepository].
///
/// Responsibilities kept here (and nowhere else):
/// * caching the session after every successful call,
/// * handing the tokens to the [TokenStore] the API client authenticates with,
/// * keeping the in-memory session in sync when the profile changes,
/// * translating datasource payloads into domain objects.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    TokenStore? tokens,
    this.onSessionStarted,
    this.onSessionEnded,
  }) : _remote = remote,
       _local = local,
       _tokens = tokens {
    _session = _local.readSession();
  }

  /// Called once a session exists and its token has been stored.
  ///
  /// Callbacks rather than a direct dependency, so this layer stays unaware of
  /// the socket: every sign-in path funnels through `_persist`, which makes
  /// this the one place a connection can be opened without repeating it in
  /// login, OTP, social and registration.
  final void Function()? onSessionStarted;

  /// Called once the session is gone, so anything holding it can let go.
  final void Function()? onSessionEnded;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  /// Where the API client reads the bearer token from.
  ///
  /// Signing in has to write here, not only into the local session cache:
  /// nothing else does, so without it every authenticated request after a
  /// sign-in goes out with no `Authorization` header and comes back 401.
  final TokenStore? _tokens;

  AuthSessionModel? _session;

  @override
  AuthSession? get currentSession => _session;

  @override
  bool get isSignedIn => _session != null && _local.hasSession;

  /// The bearer token for authenticated calls.
  ///
  /// Throws rather than sending an empty header, so a lost session surfaces
  /// as a clear error instead of a confusing 401.
  String get _token {
    final token = _session?.accessToken;
    if (token == null || token.isEmpty) {
      throw UnknownException('No active session');
    }
    return token;
  }

  Future<AuthSession> _persist(AuthSessionModel session) async {
    _session = session;
    await _local.writeSession(session);
    if (session.accessToken.isNotEmpty) {
      await _tokens?.save(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken ?? '',
      );
      // After the token is stored, never before: the socket handshake reads
      // it from the same store, so connecting first would authenticate with
      // whatever the previous session left there.
      onSessionStarted?.call();
    }
    return session;
  }

  /// Replaces the cached user while keeping the existing tokens.
  Future<UserEntity> _persistUser(UserModel user) async {
    final current = _session;
    if (current == null) return user;
    final updated = AuthSessionModel(
      accessToken: current.accessToken,
      refreshToken: current.refreshToken,
      user: user,
    );
    await _persist(updated);
    return user;
  }

  OtpChallenge _challengeFrom(Map<String, dynamic> json, String phoneNumber) {
    return OtpChallenge(
      verificationId: json['verification_id'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? phoneNumber,
      resendCooldown: Duration(
        seconds: (json['resend_cooldown_seconds'] as num?)?.toInt() ?? 60,
      ),
    );
  }

  // ─── Phone / OTP ─────────────────────────────────────────────────────────

  @override
  Future<OtpChallenge> requestOtp({required String phoneNumber}) async {
    final json = await _remote.requestOtp(phoneNumber);
    return _challengeFrom(json, phoneNumber);
  }

  @override
  Future<AuthSession> verifyOtp({
    required OtpChallenge challenge,
    required String code,
  }) async {
    final session = await _remote.verifyOtp(
      verificationId: challenge.verificationId,
      code: code,
    );
    return _persist(session);
  }

  // ─── Email / social ──────────────────────────────────────────────────────

  @override
  Future<AuthSession> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final session = await _remote.loginWithEmail(
      email: email,
      password: password,
    );
    return _persist(session);
  }

  @override
  Future<AuthSession> signInWithProvider(SocialProvider provider) async {
    // The provider SDK (google_sign_in / sign_in_with_apple) resolves the id
    // token; until it is wired up the datasource accepts an empty one.
    final session = await _remote.socialLogin(
      provider: provider.name,
      idToken: '',
    );
    return _persist(session);
  }

  // ─── Registration ────────────────────────────────────────────────────────

  @override
  Future<UserEntity> saveProfileDetails({
    required String name,
    required Gender gender,
    required AgeRange ageRange,
  }) async {
    final user = await _remote.saveProfileDetails(
      token: _token,
      body: {'name': name, 'gender': gender.value, 'age_range': ageRange.label},
    );
    return _persistUser(user);
  }

  @override
  Future<UserEntity> saveCredentials({
    required String email,
    required String password,
  }) async {
    final user = await _remote.saveCredentials(
      token: _token,
      body: {'email': email, 'password': password},
    );
    return _persistUser(user);
  }

  // ─── Password recovery ───────────────────────────────────────────────────

  @override
  Future<OtpChallenge> requestPasswordResetOtp({
    required String phoneNumber,
  }) async {
    final json = await _remote.requestPasswordResetOtp(phoneNumber);
    return _challengeFrom(json, phoneNumber);
  }

  @override
  Future<String> verifyPasswordResetOtp({
    required OtpChallenge challenge,
    required String code,
  }) {
    return _remote.verifyPasswordResetOtp(
      verificationId: challenge.verificationId,
      code: code,
    );
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) {
    return _remote.resetPassword(
      resetToken: resetToken,
      newPassword: newPassword,
    );
  }

  // ─── Session ─────────────────────────────────────────────────────────────

  @override
  Future<void> logout() async {
    try {
      if (_session != null) await _remote.logout(_token);
    } on AppException {
      // A failed server-side logout must not strand the user in a signed-in
      // state locally — clearing below is what actually signs them out.
    } finally {
      _session = null;
      await _local.clear();
      await _tokens?.clear();
      // The socket authenticated as the user who just left; leaving it open
      // would keep them present and still delivering their messages.
      onSessionEnded?.call();
    }
  }
}
