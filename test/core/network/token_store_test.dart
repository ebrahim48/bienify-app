import 'package:bienify_app/core/network/token_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the signal the socket re-authenticates on.
///
/// The socket handshakes once with whatever access token was current when it
/// connected, and socket.io replays that same payload on every reconnect. With
/// nothing announcing a refresh, the first drop after the 15-minute access
/// token expired reconnected with a dead token, was refused, and retried the
/// dead token for the rest of the session — live tracking and chat both down
/// while HTTP carried on working.
///
/// `save` and `clear` are deliberately not overridable for this reason, so
/// these tests are as much about the shape as the behaviour: a store that can
/// persist without announcing brings the silence straight back.
void main() {
  group('TokenStore.changes', () {
    test('fires when a refresh replaces the pair', () async {
      final store = MemoryTokenStore(access: 'old', refresh: 'r0');
      final seen = <String?>[];
      final sub = store.changes.listen((_) => seen.add(store.accessToken));

      await store.save(accessToken: 'new', refreshToken: 'r1');
      // The stream is asynchronous, so let it deliver before asserting.
      await Future<void>.delayed(Duration.zero);

      expect(seen, ['new']);
      await sub.cancel();
      await store.dispose();
    });

    test('fires on sign-out, so the socket drops with the session', () async {
      final store = MemoryTokenStore(access: 'live', refresh: 'r0');
      final seen = <String?>[];
      final sub = store.changes.listen((_) => seen.add(store.accessToken));

      await store.clear();
      await Future<void>.delayed(Duration.zero);

      expect(seen, [null]);
      await sub.cancel();
      await store.dispose();
    });

    test('a late listener does not miss later changes', () async {
      final store = MemoryTokenStore(access: 'a', refresh: 'r0');
      await store.save(accessToken: 'b', refreshToken: 'r1');

      // Broadcast, so a screen that subscribes after start-up still hears the
      // refreshes that follow it.
      final seen = <String?>[];
      final sub = store.changes.listen((_) => seen.add(store.accessToken));
      await store.save(accessToken: 'c', refreshToken: 'r2');
      await Future<void>.delayed(Duration.zero);

      expect(seen, ['c']);
      await sub.cancel();
      await store.dispose();
    });
  });
}
