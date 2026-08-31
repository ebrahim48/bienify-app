// Telling the platform which phone to push to — and untelling it.
//
// The notification list was pull-to-refresh only: nothing woke the app for an
// appointment reminder, an order moving or a message. The server can address a
// device now; this is the half that gives it the address, and the half that
// takes it back when the session ends.
//
// The withdrawal is the part worth testing hardest. On a telemedicine platform
// a token left registered means the next person holding the phone receives the
// previous patient's appointments and prescriptions.
import 'package:bienify_app/core/constants/api_constants.dart';
import 'package:bienify_app/core/network/api_client.dart';
import 'package:bienify_app/core/network/token_store.dart';
import 'package:bienify_app/core/services/push_registration_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../core/network/api_client_test.dart' show FakeAdapter, ok;

class _FixedToken implements PushTokenSource {
  _FixedToken(this.value);

  final String? value;

  @override
  Future<String?> token() async => value;
}

({ApiClient client, FakeAdapter adapter}) buildClient() {
  final adapter = FakeAdapter((_) => ok({'registered': true}));
  final dio = Dio(ApiClient.baseOptions())..httpClientAdapter = adapter;
  final refreshDio = Dio(ApiClient.baseOptions())..httpClientAdapter = adapter;
  return (
    client: ApiClient(
      tokens: MemoryTokenStore(access: 'access', refresh: 'refresh'),
      dio: dio,
      refreshDio: refreshDio,
    ),
    adapter: adapter,
  );
}

void main() {
  test('registering sends the device token and its platform', () async {
    final b = buildClient();
    final service = PushRegistrationService(
      api: b.client,
      source: _FixedToken('fcm-token-abcdef'),
    );

    await service.register();

    final sent = b.adapter.requests.single;
    expect(sent.path, ApiConstants.postNotificationsDevices);
    expect(sent.method, 'POST');
    expect((sent.data as Map)['token'], 'fcm-token-abcdef');
    // The server stores it per platform, and 'web' is not a thing this app is.
    expect((sent.data as Map)['platform'], anyOf('android', 'ios'));
  });

  test('signing out withdraws exactly the token that was registered', () async {
    final b = buildClient();
    final service = PushRegistrationService(
      api: b.client,
      source: _FixedToken('fcm-token-abcdef'),
    );

    await service.register();
    await service.unregister();

    expect(b.adapter.requests, hasLength(2));
    final withdrawal = b.adapter.requests.last;
    expect(withdrawal.method, 'DELETE');
    expect(
      withdrawal.path,
      ApiConstants.deleteNotificationsDevices('fcm-token-abcdef'),
    );
  });

  test('no push token means nothing is registered at all', () async {
    // The default source until Firebase is configured. Registering a device
    // that can never be delivered to would leave the server pushing into the
    // void and the collection filling with dead addresses.
    final b = buildClient();
    final service = PushRegistrationService(
      api: b.client,
      source: _FixedToken(null),
    );

    await service.register();

    expect(b.adapter.requests, isEmpty);
  });

  test('signing out without having registered sends nothing', () async {
    final b = buildClient();
    final service = PushRegistrationService(
      api: b.client,
      source: _FixedToken(null),
    );

    await service.register();
    await service.unregister();

    expect(b.adapter.requests, isEmpty);
  });

  test('a second sign-out does not withdraw twice', () async {
    final b = buildClient();
    final service = PushRegistrationService(
      api: b.client,
      source: _FixedToken('fcm-token-abcdef'),
    );

    await service.register();
    await service.unregister();
    await service.unregister();

    // Two calls, not three: the token is forgotten locally on the first.
    expect(b.adapter.requests, hasLength(2));
  });
}
