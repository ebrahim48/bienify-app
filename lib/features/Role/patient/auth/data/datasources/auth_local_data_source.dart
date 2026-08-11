import 'dart:convert';

import '../../../../../../core/services/storage_service.dart';
import '../models/auth_session_model.dart';

/// Persists the signed-in session so a returning user skips onboarding.
///
/// Only this class knows the storage encoding; the repository works with
/// [AuthSessionModel] objects.
class AuthLocalDataSource {
  const AuthLocalDataSource(this._storage);

  final StorageService _storage;

  static const String _sessionKey = 'auth_session';

  AuthSessionModel? readSession() {
    final raw = _storage.getString(_sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthSessionModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      // Corrupted payload — drop it rather than trapping the user on a
      // launch-time crash.
      clear();
      return null;
    }
  }

  Future<void> writeSession(AuthSessionModel session) async {
    await _storage.setString(_sessionKey, jsonEncode(session.toJson()));
    await _storage.setString(StorageKeys.authToken, session.accessToken);
    await _storage.setBool(StorageKeys.isLoggedIn, true);
    final refreshToken = session.refreshToken;
    if (refreshToken != null) {
      await _storage.setString(StorageKeys.refreshToken, refreshToken);
    }
  }

  bool get hasSession => _storage.getBool(StorageKeys.isLoggedIn) ?? false;

  /// True once the location prompt has been answered, so it is only ever
  /// shown on a first run.
  bool get hasSeenLocationPrompt =>
      _storage.getBool(_locationPromptKey) ?? false;

  Future<void> markLocationPromptSeen() =>
      _storage.setBool(_locationPromptKey, true);

  Future<void> clear() async {
    await _storage.remove(_sessionKey);
    await _storage.remove(StorageKeys.authToken);
    await _storage.remove(StorageKeys.refreshToken);
    await _storage.setBool(StorageKeys.isLoggedIn, false);
  }

  static const String _locationPromptKey = 'location_prompt_seen';
}
