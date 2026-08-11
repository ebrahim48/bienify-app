import 'dart:convert';
import 'dart:typed_data';

import 'package:bienify_app/core/constants/api_constants.dart';
import 'package:bienify_app/core/exceptions/app_exceptions.dart';
import 'package:bienify_app/core/network/api_client.dart';
import 'package:bienify_app/core/network/token_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// A scripted stand-in for the network.
///
/// Records every request so a test can assert on what was actually sent —
/// asserting that a mock "was called" proves nothing about which header went
/// out on the wire.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  int countFor(String path) =>
      requests.where((r) => r.path.contains(path)).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody json(Object body, int status) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

ResponseBody ok(Object data) => json({'success': true, 'data': data}, 200);

ResponseBody err(int status, String message, {List<Object>? details}) => json({
  'success': false,
  'error': {'message': message, if (details != null) 'details': details},
}, status);

/// Builds a client whose request and refresh channels share one adapter, so a
/// test can count refreshes against the same script.
({ApiClient client, FakeAdapter adapter}) build(
  ResponseBody Function(RequestOptions) handler, {
  TokenStore? tokens,
}) {
  final adapter = FakeAdapter(handler);
  final store = tokens ?? MemoryTokenStore(access: 'old-access', refresh: 'r1');
  // Built from the app's own options, not hand-rolled ones, so a regression
  // in the real transport config fails here.
  final dio = Dio(ApiClient.baseOptions())..httpClientAdapter = adapter;
  final refreshDio = Dio(ApiClient.baseOptions())..httpClientAdapter = adapter;
  return (
    client: ApiClient(tokens: store, dio: dio, refreshDio: refreshDio),
    adapter: adapter,
  );
}

void main() {
  group('envelope', () {
    test('unwraps data out of the success envelope', () async {
      final b = build((_) => ok({'id': 'u1', 'name': 'Ada'}));
      expect(await b.client.getMap('/api/v1/users/me'), {
        'id': 'u1',
        'name': 'Ada',
      });
    });

    test('reads a paged list from items', () async {
      final b = build(
        (_) => ok({
          'items': [
            {'id': 'a'},
            {'id': 'b'},
          ],
          'total': 2,
        }),
      );
      expect(await b.client.getList('/api/v1/doctors'), hasLength(2));
    });

    test('reads a bare array', () async {
      final b = build(
        (_) => ok([
          {'id': 'a'},
        ]),
      );
      expect(await b.client.getList('/api/v1/specialties'), hasLength(1));
    });
  });

  group('auth header', () {
    test('attaches the bearer token', () async {
      final b = build((_) => ok({}));
      await b.client.get('/api/v1/users/me');
      expect(
        b.adapter.requests.single.headers['Authorization'],
        'Bearer old-access',
      );
    });

    // Sending a stale token to login would be harmless, but sending one to
    // refresh makes the server rotate the wrong session.
    test('does not attach a token to login', () async {
      final b = build((_) => ok({}));
      await b.client.post(ApiConstants.postAuthLogin, body: {});
      expect(
        b.adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('sends no header when signed out', () async {
      final b = build((_) => ok({}), tokens: MemoryTokenStore());
      await b.client.get('/api/v1/doctors');
      expect(
        b.adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });
  });

  group('token refresh', () {
    test('renews an expired token and retries the original request', () async {
      var served = 0;
      final store = MemoryTokenStore(access: 'expired', refresh: 'r1');
      final b = build((o) {
        if (o.path.contains('/auth/refresh')) {
          return ok({'accessToken': 'fresh', 'refreshToken': 'r2'});
        }
        // The first attempt carries the expired token; the retry carries the
        // new one and is the call that must succeed.
        served++;
        return o.headers['Authorization'] == 'Bearer fresh'
            ? ok({'id': 'u1'})
            : err(401, 'Token expired');
      }, tokens: store);

      expect(await b.client.getMap('/api/v1/users/me'), {'id': 'u1'});
      expect(served, 2, reason: 'original attempt, then the retry');
      expect(store.accessToken, 'fresh');
      expect(store.refreshToken, 'r2', reason: 'rotation must be persisted');
    });

    // The backend revokes every session when a rotated refresh token is used
    // twice. Five parallel 401s must therefore produce one refresh, not five.
    test('refreshes once for concurrent failures', () async {
      final store = MemoryTokenStore(access: 'expired', refresh: 'r1');
      final b = build((o) {
        if (o.path.contains('/auth/refresh')) {
          return ok({'accessToken': 'fresh', 'refreshToken': 'r2'});
        }
        return o.headers['Authorization'] == 'Bearer fresh'
            ? ok({'ok': true})
            : err(401, 'Token expired');
      }, tokens: store);

      await Future.wait<dynamic>([
        b.client.get('/api/v1/users/me'),
        b.client.get('/api/v1/appointments'),
        b.client.get('/api/v1/notifications'),
        b.client.get('/api/v1/wallet'),
        b.client.get('/api/v1/orders'),
      ]);

      expect(b.adapter.countFor('/auth/refresh'), 1);
    });

    test('clears the session when the refresh token is spent', () async {
      final store = MemoryTokenStore(access: 'expired', refresh: 'spent');
      final b = build((o) {
        if (o.path.contains('/auth/refresh')) return err(401, 'Reuse detected');
        return err(401, 'Token expired');
      }, tokens: store);

      await expectLater(
        b.client.get('/api/v1/users/me'),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(store.accessToken, isNull);
      expect(store.refreshToken, isNull);
    });

    test('does not try to refresh when signed out', () async {
      final b = build((_) => err(401, 'No token'), tokens: MemoryTokenStore());
      await expectLater(
        b.client.get('/api/v1/users/me'),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(b.adapter.countFor('/auth/refresh'), 0);
    });

    // A server that 401s even on a brand-new token must not loop forever.
    test('retries at most once', () async {
      final b = build((o) {
        if (o.path.contains('/auth/refresh')) {
          return ok({'accessToken': 'fresh', 'refreshToken': 'r2'});
        }
        return err(401, 'Still refused');
      });

      await expectLater(
        b.client.get('/api/v1/users/me'),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(b.adapter.countFor('/users/me'), 2);
      expect(b.adapter.countFor('/auth/refresh'), 1);
    });

    // Wrong password is not an expired session; refreshing would mask it.
    test('does not refresh when login itself is rejected', () async {
      final b = build((_) => err(401, 'Invalid credentials'));
      await expectLater(
        b.client.post(ApiConstants.postAuthLogin, body: {}),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(b.adapter.countFor('/auth/refresh'), 0);
    });
  });

  group('error mapping', () {
    test('400 carries the field errors', () async {
      final b = build(
        (_) => err(
          400,
          'Validation failed',
          details: [
            {
              'path': ['email'],
              'message': 'Invalid email',
            },
          ],
        ),
      );

      try {
        await b.client.post('/api/v1/auth/register', body: {});
        fail('expected a ValidationException');
      } on ValidationException catch (e) {
        expect(e.message, 'Validation failed');
        expect(e.forField('email'), 'Invalid email');
      }
    });

    test('maps each status to its own type', () async {
      Future<void> check(int status, Matcher matcher) async {
        final b = build((_) => err(status, 'nope'));
        await expectLater(b.client.get('/api/v1/x'), throwsA(matcher));
      }

      await check(403, isA<ForbiddenException>());
      await check(404, isA<NotFoundException>());
      await check(409, isA<ConflictException>());
      await check(429, isA<TooManyRequestsException>());
      await check(500, isA<ServerException>());
    });

    test("keeps the server's wording", () async {
      final b = build((_) => err(409, 'That slot was just taken'));
      await expectLater(
        b.client.post('/api/v1/appointments', body: {}),
        throwsA(
          isA<ConflictException>().having(
            (e) => e.message,
            'message',
            'That slot was just taken',
          ),
        ),
      );
    });

    test('reports an unreachable server as an offline error', () async {
      final adapter = FakeAdapter(
        (o) => throw DioException.connectionError(
          requestOptions: o,
          reason: 'refused',
        ),
      );
      final dio = Dio(ApiClient.baseOptions())..httpClientAdapter = adapter;
      final client = ApiClient(
        tokens: MemoryTokenStore(),
        dio: dio,
        refreshDio: dio,
      );

      await expectLater(
        client.get('/api/v1/doctors'),
        throwsA(isA<NoInternetException>()),
      );
    });
  });
}
