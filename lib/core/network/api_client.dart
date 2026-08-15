import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../constants/api_constants.dart';
import '../exceptions/app_exceptions.dart';
import 'auth_interceptor.dart';
import 'token_store.dart';

/// Every request and response Dio makes, printed as `[API] ...` in debug
/// builds. `printer.lineLength` is wide so a JSON body does not get chopped
/// mid-field.
final _apiLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    lineLength: 120,
    colors: false,
    printEmojis: false,
    dateTimeFormat: DateTimeFormat.none,
  ),
);

/// The single entry point for talking to the Bienify API.
///
/// Two jobs the raw Dio client does not do:
///
/// 1. **Unwraps the envelope.** Every successful response is
///    `{"success": true, "data": ...}`; callers want the `data`, and having 60
///    call sites each remember `res.data['data']` is one typo away from a
///    null-dereference in production.
/// 2. **Turns transport failures into typed exceptions** so a controller can
///    tell "you are offline" from "the server said no" from "your input was
///    rejected", instead of matching on status-code integers everywhere.
class ApiClient {
  ApiClient({
    required TokenStore tokens,
    Dio? dio,
    Dio? refreshDio,
    Future<void> Function()? onSessionExpired,
  }) : _dio = dio ?? Dio(baseOptions()),
       _tokens = tokens {
    _dio.interceptors.add(
      AuthInterceptor(
        tokens: tokens,
        refreshClient: refreshDio ?? Dio(baseOptions()),
        // Without this the interceptor clears the spent tokens and says
        // nothing: every later request goes out with no Authorization header
        // and the screen answers each tap with "Missing or malformed
        // Authorization header". Nobody passed it, so that is what an expired
        // session looked like.
        onSessionExpired: onSessionExpired,
      ),
    );
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          responseHeader: false,
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => _apiLogger.d('[API] $obj'),
        ),
      );
    }
  }

  final Dio _dio;
  final TokenStore _tokens;

  Dio get dio => _dio;
  TokenStore get tokens => _tokens;

  /// The transport configuration every Bienify call uses.
  ///
  /// Public so tests build their Dio from the same options the app does —
  /// a test that hand-sets `validateStatus` would keep passing if this
  /// config regressed, which is exactly the bug it needs to catch.
  static BaseOptions baseOptions() => BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    headers: ApiConstants.headers,
    connectTimeout: ApiConstants.connectTimeout,
    receiveTimeout: ApiConstants.receiveTimeout,
    // Only 2xx counts as success. Anything else has to raise so the auth
    // interceptor gets a chance to renew the session on a 401 — widening this
    // to `< 500` would make Dio treat 401 as a normal response, `onError`
    // would never run, and the refresh would silently never happen.
    // The server's error body is still available on `DioException.response`.
    validateStatus: (s) => s != null && s >= 200 && s < 300,
  );

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query));

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) => _send(() => _dio.post(path, data: body, queryParameters: query));

  Future<dynamic> put(String path, {Object? body}) =>
      _send(() => _dio.put(path, data: body));

  Future<dynamic> patch(String path, {Object? body}) =>
      _send(() => _dio.patch(path, data: body));

  Future<dynamic> delete(String path, {Object? body}) =>
      _send(() => _dio.delete(path, data: body));

  /// Returns the `data` object of a response, as a map.
  Future<Map<String, dynamic>> getMap(
    String path, {
    Map<String, dynamic>? query,
  }) async => _asMap(await get(path, query: query));

  Future<Map<String, dynamic>> postMap(String path, {Object? body}) async =>
      _asMap(await post(path, body: body));

  /// Returns a list payload, tolerating both a bare array and the
  /// `{items: [...], total: n}` page shape the list endpoints return.
  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final data = await get(path, query: query);
    return listFrom(data);
  }

  static List<Map<String, dynamic>> listFrom(dynamic data) {
    final raw = data is Map<String, dynamic>
        ? data['items'] ?? data['data']
        : data;
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  static Map<String, dynamic> _asMap(dynamic data) =>
      data is Map<String, dynamic> ? data : <String, dynamic>{};

  Future<dynamic> _send(Future<Response<dynamic>> Function() call) async {
    late final Response<dynamic> res;
    try {
      res = await call();
    } on DioException catch (e) {
      throw _fromDio(e);
    }

    final status = res.statusCode ?? 0;
    final body = res.data;

    if (status >= 200 && status < 300) {
      if (body is Map<String, dynamic> && body.containsKey('data')) {
        return body['data'];
      }
      return body;
    }
    throw _fromStatus(status, _messageOf(body), body);
  }

  /// The server reports failures as `{"success": false, "error": {...}}`.
  static String _messageOf(dynamic body) {
    if (body is Map<String, dynamic>) {
      final error = body['error'];
      if (error is Map && error['message'] is String) {
        return error['message'] as String;
      }
      if (body['message'] is String) return body['message'] as String;
    }
    return 'Something went wrong. Please try again.';
  }

  static AppException _fromStatus(int status, String message, dynamic body) {
    switch (status) {
      case 400:
      case 422:
        return ValidationException(message, _fieldErrors(body));
      case 401:
        return UnauthorizedException(message);
      case 403:
        return ForbiddenException(message);
      case 404:
        return NotFoundException(message);
      case 409:
        return ConflictException(message);
      case 429:
        return TooManyRequestsException(message);
      default:
        return ServerException(message, status);
    }
  }

  /// Zod reports the offending field in `error.details`; surfacing it lets a
  /// form highlight the field instead of showing a generic banner.
  static Map<String, String>? _fieldErrors(dynamic body) {
    if (body is! Map<String, dynamic>) return null;
    final error = body['error'];
    if (error is! Map) return null;
    final details = error['details'];
    if (details is! List) return null;

    final out = <String, String>{};
    for (final item in details) {
      if (item is Map && item['path'] != null && item['message'] is String) {
        final path = item['path'];
        final field = path is List ? path.join('.') : path.toString();
        out[field] = item['message'] as String;
      }
    }
    return out.isEmpty ? null : out;
  }

  static AppException _fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          'The server took too long to respond. Please try again.',
        );
      case DioExceptionType.connectionError:
        return NoInternetException(
          'Cannot reach the server. Check your connection.',
        );
      case DioExceptionType.cancel:
        return RequestCancelledException('The request was cancelled.');
      default:
        final res = e.response;
        if (res != null) {
          return _fromStatus(
            res.statusCode ?? 0,
            _messageOf(res.data),
            res.data,
          );
        }
        return UnknownException(e.message ?? 'Unexpected error');
    }
  }
}
