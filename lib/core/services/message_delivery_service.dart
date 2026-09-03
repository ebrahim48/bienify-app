import 'dart:async';

import 'package:get/get.dart';

import '../models/chat_thread.dart';
import '../network/socket_service.dart';
import '../network/token_store.dart';

/// Tells the sender that a message reached this device.
///
/// The middle tick. `markDelivered` existed on the socket and on the server
/// from the beginning and nothing ever called it, so a message went straight
/// from sent to read and only when the recipient happened to open the thread.
/// A message sitting on a phone that plainly had it showed one tick for hours.
///
/// Delivered is answered by the device, not inferred by the server: the server
/// knows a socket is connected, which is not the same as the message having
/// arrived. Saying so from here means the tick is true — this client is
/// holding the message when it reports it.
///
/// Registered permanently, because delivery does not depend on which screen
/// the recipient is looking at. That is the whole difference between delivered
/// and read.
class MessageDeliveryService extends GetxService {
  MessageDeliveryService({required SocketService socket, TokenStore? tokens})
    : _socket = socket,
      _tokens = tokens;

  final SocketService _socket;
  final TokenStore? _tokens;

  StreamSubscription<Map<String, dynamic>>? _messages;
  StreamSubscription<bool>? _connection;

  @override
  void onInit() {
    super.onInit();
    _messages = _socket.messages.listen(_onMessage);
    // Coming online is when everything sent while this device was unreachable
    // becomes delivered. Without this a message sent to a closed app sat on a
    // single tick until its thread happened to be opened — and opening a
    // thread marks messages *read*, so the sender's bubble jumped from sent
    // straight to seen and the middle state never appeared at all.
    _connection = _socket.connectionState.listen((isUp) {
      if (isUp) _socket.markAllDelivered();
    });
  }

  @override
  void onClose() {
    unawaited(_messages?.cancel());
    unawaited(_connection?.cancel());
    super.onClose();
  }

  void _onMessage(Map<String, dynamic> json) {
    final thread = ChatThread.fromJson(json);
    if (thread == null || !thread.isLive) return;

    // Our own message echoed back to us. Reporting it would tick the sender's
    // bubble the moment they sent it, which says nothing about the recipient.
    final senderId = '${json['senderId'] ?? ''}';
    final me = _tokens?.userId;
    if (me == null || senderId == me) return;

    // Already delivered — a history read, or a second device of ours.
    if (json['deliveredAt'] != null) return;

    // Every arriving message, without a per-thread guard.
    //
    // A guard looked like it would spare the server a round trip and instead
    // broke the feature: `markDelivered` marks whatever is undelivered *now*,
    // so remembering that a thread had already been reported meant the second
    // message in a conversation was never acknowledged at all. The server
    // marks only what changed and stays silent when nothing did, so an extra
    // call costs one small emit and no broadcast.
    _socket.markDelivered(thread);
  }
}
