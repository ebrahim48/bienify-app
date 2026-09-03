import 'dart:async';

import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import 'token_store.dart';

/// Attaches the bearer token to outgoing requests and renews it once when the
/// server rejects it.
///
/// The refresh is deliberately **single-flight**: the backend rotates the
/// refresh token on every use and treats a second use of an already-rotated
/// token as theft, revoking every session for that user. A screen that fires
/// five requests at once would, without this guard, send five refreshes — the
/// first succeeds and the other four look exactly like a stolen token being
/// replayed, signing the user out. So the first 401 starts the refresh and
/// every other caller awaits that same future.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStore tokens,
    required Dio refreshClient,
    Future<void> Function()? onSessionExpired,
  }) : _tokens = tokens,
       _refreshClient = refreshClient,
       _onSessionExpired = onSessionExpired;

  final TokenStore _tokens;

  /// A separate Dio without this interceptor — refreshing through the same
  /// client would recurse when the refresh call itself returns 401.
  final Dio _refreshClient;

  final Future<void> Function()? _onSessionExpired;

  Future<String?>? _inFlight;

  /// Endpoints that must never carry a stale bearer token or trigger a
  /// refresh: they are how a session is established in the first place.
  static const _public = <String>{
    ApiConstants.postAuthLogin,
    ApiConstants.postAuthRegister,
    ApiConstants.postAuthRefresh,
    ApiConstants.postAuthOtpRequest,
    ApiConstants.postAuthOtpVerify,
  };

  bool _isPublic(String path) => _public.any(path.contains);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokens.accessToken;
    if (token != null && token.isNotEmpty && !_isPublic(options.path)) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final isAuthFailure = response?.statusCode == 401;
    final path = err.requestOptions.path;

    // A 401 from login or refresh means the credentials are genuinely wrong,
    // not that the access token aged out — retrying would loop forever.
    if (!isAuthFailure ||
        _isPublic(path) ||
        err.requestOptions.extra['__retried__'] == true) {
      return handler.next(err);
    }

    if (_tokens.refreshToken == null) {
      return handler.next(err);
    }

    final fresh = await _refreshOnce();
    if (fresh == null) {
      await _onSessionExpired?.call();
      return handler.next(err);
    }

    try {
      final retried = await _retry(err.requestOptions, fresh);
      return handler.resolve(retried);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  /// Renews the access token on demand, for a caller that is not an HTTP
  /// request.
  ///
  /// The socket needs this. It authenticates once in its handshake and
  /// socket.io replays that same payload on every reconnect, so when the
  /// 15-minute access token expires the next drop is refused and every retry
  /// after it replays the same dead token. Nothing recovered that on its own:
  /// the refresh here only ever ran off a 401, and a client sitting in a chat
  /// makes no HTTP requests at all — so messages, typing, presence and read
  /// receipts stayed down while the app looked perfectly connected.
  ///
  /// Shares the single-flight guard with the 401 path deliberately: two
  /// refreshes in flight look to the server exactly like a stolen refresh
  /// token being replayed, and it revokes every session for that user.
  Future<String?> refreshTokens() => _refreshOnce();

  Future<String?> _refreshOnce() {
    // Whoever gets here first owns the refresh; everyone else awaits it.
    return _inFlight ??= _performRefresh().whenComplete(() => _inFlight = null);
  }

  Future<String?> _performRefresh() async {
    try {
      final res = await _refreshClient.post(
        ApiConstants.postAuthRefresh,
        data: {'refreshToken': _tokens.refreshToken},
      );
      final data = res.data['data'] as Map<String, dynamic>;
      final access = data['accessToken'] as String;
      final refresh = data['refreshToken'] as String;
      await _tokens.save(accessToken: access, refreshToken: refresh);
      return access;
    } on DioException {
      // The refresh token is spent, revoked, or the account was suspended.
      await _tokens.clear();
      return null;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions req, String token) {
    return _refreshClient.fetch(
      req.copyWith(
        headers: {...req.headers, 'Authorization': 'Bearer $token'},
        extra: {...req.extra, '__retried__': true},
      ),
    );
  }
}
