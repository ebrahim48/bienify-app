// The middle tick.
//
// `markDelivered` existed on the socket and on the server from the beginning
// and nothing ever called it, so a message went straight from sent to read —
// and only when the recipient happened to open the thread. A message sitting
// on a phone that plainly had it showed one tick for hours.
//
// Delivered is answered by the device rather than inferred by the server: a
// connected socket is not the same as the message having arrived. Reporting it
// from the client is what makes the tick true.

import 'dart:async';
import 'dart:convert';

import 'package:bienify_app/core/models/chat_thread.dart';
import 'package:bienify_app/core/network/socket_service.dart';
import 'package:bienify_app/core/network/token_store.dart';
import 'package:bienify_app/core/services/message_delivery_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// A JWT the token store can read a subject out of.
String _tokenFor(String userId) {
  String b64(Map<String, Object?> claims) =>
      base64Url.encode(utf8.encode(jsonEncode(claims))).replaceAll('=', '');
  return '${b64({'alg': 'HS256'})}.${b64({'sub': userId, 'role': 'patient'})}.sig';
}

/// A socket that records what was reported and can publish arrivals.
class _Socket extends SocketService {
  _Socket() : super(tokens: MemoryTokenStore());

  final _feed = StreamController<Map<String, dynamic>>.broadcast();

  /// Threads reported delivered, in order.
  final List<String> delivered = [];

  /// How many times the whole backlog was reported.
  int sweeps = 0;

  final _connection = StreamController<bool>.broadcast();

  @override
  Stream<bool> get connectionState => _connection.stream;

  @override
  void markAllDelivered() => sweeps += 1;

  /// Brings the connection up or down, as the real socket would.
  void setConnected(bool isUp) => _connection.add(isUp);

  @override
  Stream<Map<String, dynamic>> get messages => _feed.stream;

  @override
  void markDelivered(ChatThread thread) => delivered.add(thread.key);

  @override
  void connect() {}

  void deliver(Map<String, dynamic> json) => _feed.add(json);

  @override
  void dispose() {
    unawaited(_feed.close());
    unawaited(_connection.close());
    super.dispose();
  }
}

void main() {
  late _Socket socket;
  late MessageDeliveryService service;

  Map<String, dynamic> message({
    String appointmentId = 'a',
    String senderId = 'them',
    String? deliveredAt,
  }) => {
    '_id': 'm-${DateTime.now().microsecondsSinceEpoch}',
    'appointmentId': appointmentId,
    'senderId': senderId,
    'body': 'hello',
    'deliveredAt': deliveredAt,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
  };

  setUp(() {
    Get.testMode = true;
    socket = _Socket();
    service = MessageDeliveryService(
      socket: socket,
      tokens: MemoryTokenStore(access: _tokenFor('me')),
    );
    service.onInit();
  });

  tearDown(() {
    service.onClose();
    socket.dispose();
    Get.reset();
  });

  test('reports a message that reached this device', () async {
    socket.deliver(message());
    await Future<void>.delayed(Duration.zero);

    expect(socket.delivered, ['appointment:a']);
  });

  test('reports every message, not just the first in a thread', () async {
    // A per-thread guard looked like it would spare the server a round trip
    // and instead broke the feature: `markDelivered` marks whatever is
    // undelivered *now*, so the second message in a conversation would never
    // be acknowledged at all.
    socket.deliver(message());
    socket.deliver(message());
    await Future<void>.delayed(Duration.zero);

    expect(socket.delivered, ['appointment:a', 'appointment:a']);
  });

  test('does not report our own message back to us', () async {
    // The server echoes a send to the sender's own room. Reporting it would
    // tick the sender's bubble the moment they sent it, which says nothing
    // about whether the other person's phone has it.
    socket.deliver(message(senderId: 'me'));
    await Future<void>.delayed(Duration.zero);

    expect(socket.delivered, isEmpty);
  });

  test('does not re-report one already delivered', () async {
    socket.deliver(message(deliveredAt: '2026-09-02T08:00:00.000Z'));
    await Future<void>.delayed(Duration.zero);

    expect(socket.delivered, isEmpty);
  });

  test('reports the whole backlog when the connection comes up', () async {
    // A message sent while this device was unreachable has nobody to report
    // it. Coming online is exactly when it becomes delivered — without this it
    // sat on one tick until its thread happened to be opened, and opening a
    // thread marks messages *read*, so the sender's bubble jumped from sent
    // straight to seen with no middle state at all.
    expect(socket.sweeps, 0);

    socket.setConnected(true);
    await Future<void>.delayed(Duration.zero);

    expect(socket.sweeps, 1);
  });

  test('sweeps again after a reconnect', () async {
    socket.setConnected(true);
    await Future<void>.delayed(Duration.zero);
    socket.setConnected(false);
    socket.setConnected(true);
    await Future<void>.delayed(Duration.zero);

    // Anything that arrived during the gap was never reported by this device.
    expect(socket.sweeps, 2);
  });

  test('does not sweep when the connection goes down', () async {
    socket.setConnected(false);
    await Future<void>.delayed(Duration.zero);

    expect(socket.sweeps, 0);
  });

  test('reports a courier thread too', () async {
    // Delivery is not a consultation feature; a customer waiting on a parcel
    // wants the same tick.
    socket.deliver({
      '_id': 'm-1',
      'deliveryId': 'd-1',
      'senderId': 'rider',
      'body': 'outside',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
    await Future<void>.delayed(Duration.zero);

    expect(socket.delivered, ['delivery:d-1']);
  });

  test('says nothing when it cannot tell whose message it is', () async {
    // Signed out, or a token that carries no subject. Reporting delivery for
    // a message that might be our own would tick the sender's bubble on no
    // evidence at all.
    final blind = MessageDeliveryService(
      socket: socket,
      tokens: MemoryTokenStore(),
    );
    blind.onInit();
    addTearDown(blind.onClose);
    socket.delivered.clear();

    socket.deliver(message());
    await Future<void>.delayed(Duration.zero);

    // Only the service that knows who it is reported anything.
    expect(socket.delivered, ['appointment:a']);
  });
}
