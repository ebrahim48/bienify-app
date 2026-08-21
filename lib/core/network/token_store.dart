import 'dart:convert';

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

  /// The signed-in user's id, read from the access token's `sub` claim.
  ///
  /// The server already tells us who we are on every request; asking it again
  /// over HTTP just to learn our own id would be a round trip for something we
  /// are holding. Null when signed out or when the token is not a JWT.
  ///
  /// This is *not* a security check — the payload is only base64, not
  /// verified. It is used to tell my own reactions and receipts apart from the
  /// other party's, which the server re-checks on every write anyway.
  String? get userId {
    final token = accessToken;
    if (token == null) return null;

    final parts = token.split('.');
    if (parts.length != 3) return null;

    try {
      // `base64Url.normalize` supplies the padding JWTs omit; without it a
      // payload whose length is not a multiple of four throws.
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map) return null;
      final sub = payload['sub'];
      return sub == null ? null : '$sub';
    } catch (_) {
      return null;
    }
  }
}

/// The production store, backed by [StorageService].
///
/// Tokens are mirrored in memory because the interceptor reads the access
/// token on every single request, and a disk read per request is wasteful.
class PrefsTokenStore extends TokenStore {
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
class MemoryTokenStore extends TokenStore {
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
