import '../services/storage_service.dart';

/// The access and refresh tokens for the signed-in session.
///
/// Kept behind a small interface so the auth interceptor can be tested against
/// an in-memory implementation without touching SharedPreferences.
abstract class TokenStore {
  String? get accessToken;
  String? get refreshToken;

  Future<void> save({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> clear();
}

/// The production store, backed by [StorageService].
///
/// Tokens are mirrored in memory because the interceptor reads the access
/// token on every single request, and a disk read per request is wasteful.
class PrefsTokenStore implements TokenStore {
  PrefsTokenStore(this._storage) {
    _access = _storage.getString(StorageKeys.authToken);
    _refresh = _storage.getString(StorageKeys.refreshToken);
  }

  final StorageService _storage;
  String? _access;
  String? _refresh;

  @override
  String? get accessToken => _access;

  @override
  String? get refreshToken => _refresh;

  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    _access = accessToken;
    _refresh = refreshToken;
    await _storage.setString(StorageKeys.authToken, accessToken);
    await _storage.setString(StorageKeys.refreshToken, refreshToken);
    await _storage.setBool(StorageKeys.isLoggedIn, true);
  }

  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
    await _storage.remove(StorageKeys.authToken);
    await _storage.remove(StorageKeys.refreshToken);
    await _storage.setBool(StorageKeys.isLoggedIn, false);
  }
}

/// An in-memory store for tests.
class MemoryTokenStore implements TokenStore {
  MemoryTokenStore({String? access, String? refresh})
    : _access = access,
      _refresh = refresh;

  String? _access;
  String? _refresh;

  @override
  String? get accessToken => _access;

  @override
  String? get refreshToken => _refresh;

  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    _access = accessToken;
    _refresh = refreshToken;
  }

  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
  }
}
