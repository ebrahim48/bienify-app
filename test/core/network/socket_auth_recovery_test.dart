// What happens when the socket's own credential expires underneath it.
//
// The access token lives fifteen minutes. socket.io holds the auth payload it
// was built with and replays it on every reconnect, so once that token expired
// the first drop — a screen lock, a change of network — was refused, and every
// retry replayed the same dead token. The socket never came back for the rest
// of the session while HTTP carried on working, because the auth interceptor
// only refreshes off a 401 and a client sitting in a chat makes no requests.
//
// It did not look like a connection problem. It looked like messages not
// arriving, read receipts never coming back, and presence frozen — on a screen
// that appeared perfectly connected.

import 'package:bienify_app/core/network/socket_service.dart';
import 'package:bienify_app/core/network/token_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// A token store whose values a test can move, as a refresh would.
class _Store extends TokenStore {
  _Store(this._access, this._refresh);

  String? _access;
  String? _refresh;

  @override
  String? get accessToken => _access;

  @override
  String? get refreshToken => _refresh;

  @override
  Future<void> persistTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _access = accessToken;
    _refresh = refreshToken;
  }

  @override
  Future<void> eraseTokens() async {
    _access = null;
    _refresh = null;
  }
}

void main() {
  late _Store tokens;
  late int refreshes;

  setUp(() {
    tokens = _Store('expired-access', 'refresh-1');
    refreshes = 0;
  });

  SocketService build({
    Future<void> Function()? onRefresh,
    Duration cooldown = const Duration(seconds: 30),
  }) => SocketService(
    tokens: tokens,
    renewalCooldown: cooldown,
    refreshTokens:
        onRefresh ??
        () async {
          refreshes += 1;
          await tokens.save(
            accessToken: 'fresh-access-$refreshes',
            refreshToken: 'refresh-${refreshes + 1}',
          );
        },
  );

  test('renews the access token when the handshake is refused', () async {
    final socket = build();
    addTearDown(socket.dispose);

    socket.handleConnectError('Invalid or expired access token');
    await Future<void>.delayed(Duration.zero);

    // Without this the socket retried the same dead token forever.
    expect(refreshes, 1);
    expect(tokens.accessToken, 'fresh-access-1');
  });

  test('does not spend a refresh token on a network failure', () async {
    final socket = build();
    addTearDown(socket.dispose);

    // The backend treats a replayed refresh token as theft and revokes every
    // session for that user, so a timeout must not reach for one.
    socket.handleConnectError('timeout');
    socket.handleConnectError('xhr poll error');
    await Future<void>.delayed(Duration.zero);

    expect(refreshes, 0);
  });

  test('asks once, however many attempts are refused', () async {
    final socket = build();
    addTearDown(socket.dispose);

    // Reconnection retries arrive in a burst; each one is refused. Two
    // refreshes in flight look exactly like a stolen token being replayed.
    socket.handleConnectError('Invalid or expired access token');
    socket.handleConnectError('Invalid or expired access token');
    socket.handleConnectError('Invalid or expired access token');
    await Future<void>.delayed(Duration.zero);

    expect(refreshes, 1);
  });

  test('can renew again once the cooldown has passed', () async {
    // Only clearing the guard on a successful connect was the original bug in
    // a new shape: if the reconnect straight after a renewal failed — and it
    // can, the old socket is still tearing down — nothing would ever ask for a
    // token again and the session stayed silently dead.
    final socket = build(cooldown: const Duration(milliseconds: 40));
    addTearDown(socket.dispose);

    socket.handleConnectError('Invalid or expired access token');
    await Future<void>.delayed(Duration.zero);
    expect(refreshes, 1);

    // Still inside the cooldown: one refusal per renewal, not one each.
    socket.handleConnectError('Invalid or expired access token');
    await Future<void>.delayed(Duration.zero);
    expect(refreshes, 1);

    await Future<void>.delayed(const Duration(milliseconds: 90));
    socket.handleConnectError('Invalid or expired access token');
    await Future<void>.delayed(Duration.zero);

    expect(refreshes, 2);
  });

  test('spends one renewal per burst of refused retries', () async {
    final socket = build();
    addTearDown(socket.dispose);

    socket.handleConnectError('Invalid or expired access token');
    await Future<void>.delayed(Duration.zero);
    expect(refreshes, 1);

    // Reconnect retries arrive in a burst and each one is refused. Two
    // refreshes in flight look to the server exactly like a stolen refresh
    // token being replayed, and it revokes every session for that user.
    socket.handleConnectError('Invalid or expired access token');
    await Future<void>.delayed(Duration.zero);

    expect(refreshes, 1);
  });

  test('tells a credential refusal from an unreachable server', () {
    // The wording the server's `authenticate` actually sends, versus what
    // socket.io reports when nothing answered.
    expect(SocketService.isAuthFailure('Invalid or expired access token'), isTrue);
    expect(SocketService.isAuthFailure('Missing access token'), isTrue);
    expect(SocketService.isAuthFailure('timeout'), isFalse);
    expect(SocketService.isAuthFailure('xhr poll error'), isFalse);
  });

  test('survives a refresh that fails', () async {
    final socket = build(
      onRefresh: () async {
        refreshes += 1;
        throw StateError('refresh token is spent');
      },
    );
    addTearDown(socket.dispose);

    socket.handleConnectError('Invalid or expired access token');
    await Future<void>.delayed(Duration.zero);

    // Signing out is the auth layer's job; the socket only stops asking.
    expect(refreshes, 1);
  });
}
