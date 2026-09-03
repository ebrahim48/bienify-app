import 'dart:async';

import 'package:bienify_app/core/network/socket_service.dart';

/// A socket for a test to talk through.
///
/// `CallService` is driven entirely by the six members of [CallSignalling], so
/// this is the whole of what a call needs — no websocket, no server, and no
/// back door on the real service for pushing events into its own stream.
class FakeCallSignalling implements CallSignalling {
  final _controller = StreamController<CallEvent>.broadcast();
  final _errors = StreamController<String>.broadcast();

  /// Every emit, in order, so a test can assert what went to the server.
  final List<String> sent = [];

  /// What [inviteToCall] answers with. Null stands for a socket that is down
  /// or a server that refused.
  CallEvent? inviteAnswer;

  @override
  Stream<CallEvent> get calls => _controller.stream;

  @override
  Stream<String> get errors => _errors.stream;

  /// A refusal, in the server's own words.
  void refuse(String message) => _errors.add(message);

  /// Pushes a server event at the service under test.
  void deliver(CallEvent event) => _controller.add(event);

  Future<void> close() async {
    await _controller.close();
    await _errors.close();
  }

  /// Held open so a test can act while the invite is still in flight — the
  /// window in which Cancel used to do nothing at all.
  Completer<void>? inviteGate;

  @override
  Future<CallEvent?> inviteToCall(String appointmentId) async {
    sent.add('invite:$appointmentId');
    final gate = inviteGate;
    if (gate != null) await gate.future;
    return inviteAnswer;
  }

  @override
  void acceptCall(String callId) => sent.add('accept:$callId');

  @override
  void declineCall(String callId, {String reason = 'declined'}) =>
      sent.add('decline:$callId:$reason');

  @override
  void cancelCall(String callId) => sent.add('cancel:$callId');

  @override
  void endCall(String callId) => sent.add('end:$callId');
}
