import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs every request that fails, with the server's own answer.
///
/// Added because a failing screen said only "Cannot reach the server" — the
/// text `ApiClient` gives any `DioExceptionType.connectionError` — and that
/// one sentence covers a refused connection, a dropped tunnel, a TLS fault
/// and a server that never answered. Three rider actions were reported
/// failing that way at once, and nothing recorded which of those it was, what
/// path was called, or what came back. Diagnosing it meant guessing.
///
/// Debug builds only. A release build must not print request paths and server
/// messages to the device log, and `Authorization` is stripped even here: the
/// bearer token is a live credential and a log is not the place for it.
class RequestLogInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final request = err.requestOptions;
      final method = request.method;
      final path = request.uri.toString();
      final status = err.response?.statusCode;

      // The status is the part that separates the causes: 401 is a spent
      // session, 403 a role the route refuses, 404 a path or an id that does
      // not resolve, and no status at all means the request never arrived.
      final outcome = status == null ? '${err.type.name} (no response)' : '$status';
      debugPrint('API $method $path -> $outcome');

      final body = err.response?.data;
      if (body != null) debugPrint('API  body: $body');
    }
    handler.next(err);
  }
}
