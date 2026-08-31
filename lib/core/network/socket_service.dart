import '../models/chat_thread.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/api_constants.dart';
import 'token_store.dart';

/// The names the server publishes on. Kept in one place so a typo is a
/// compile error here rather than a message that silently never arrives.
class SocketEvents {
  SocketEvents._();

  // Outbound.
  static const String joinThread = 'thread:join';
  static const String leaveThread = 'thread:leave';
  static const String sendMessage = 'message:send';
  static const String markRead = 'message:read';
  static const String markDelivered = 'message:delivered';
  static const String react = 'message:react';
  static const String typingStart = 'typing:start';
  static const String typingStop = 'typing:stop';
  static const String heartbeat = 'presence:heartbeat';
  static const String presenceQuery = 'presence:query';

  // Inbound.
  static const String messageNew = 'message:new';

  /// `{deliveryId, lat, lng, at, status}` — the courier moved.
  ///
  /// Sent to the patient and the shop, never to the courier reporting it. The
  /// tracking map polled for this on a ten-second timer, so a pin was up to an
  /// interval stale and jumped between fixes rather than moving.
  static const String deliveryLocation = 'delivery:location';
  static const String messageRead = 'message:read';
  static const String messageDelivered = 'message:delivered';
  static const String messageReacted = 'message:reacted';
  static const String typing = 'typing';
  static const String presence = 'presence';
  static const String appError = 'error:app';
}

/// Presence for one person, as the thread header shows it.
class PresenceState {
  const PresenceState({
    required this.userId,
    required this.isOnline,
    this.lastSeen,
  });

  factory PresenceState.fromJson(Map<String, dynamic> json) => PresenceState(
    userId: '${json['userId'] ?? ''}',
    isOnline: json['isOnline'] == true,
    lastSeen: json['lastSeen'] == null
        ? null
        : DateTime.tryParse('${json['lastSeen']}'),
  );

  final String userId;
  final bool isOnline;
  final DateTime? lastSeen;
}

/// Someone started or stopped typing in a thread.
class TypingState {
  const TypingState({
    required this.thread,
    required this.userId,
    required this.isTyping,
  });

  final ChatThread thread;
  final String userId;
  final bool isTyping;
}

/// Receipts for messages the signed-in user sent.
class ReceiptState {
  const ReceiptState({
    required this.thread,
    required this.messageIds,
    required this.isRead,
  });

  final ChatThread thread;
  final List<String> messageIds;

  /// True for read, false for merely delivered.
  final bool isRead;
}

/// The app's one socket.
///
/// Messaging used to poll every three seconds, which was both late — a reply
/// could sit unseen that long — and wasteful, since an idle thread still asked
/// the server twenty times a minute.
///
/// Deliberately a *transport*, not a store: it exposes streams of what the
/// server said and holds no message state of its own. Screens keep reading
/// history over HTTP, so a client that misses events while backgrounded
/// recovers by re-reading rather than by trusting a stream it may have gaps
/// in.
class SocketService {
  SocketService({required TokenStore tokens}) : _tokens = tokens {
    // A refresh replaces the access token this socket authenticated with.
    // Without this the handshake credential silently rots: the connection
    // already open keeps working, but the next reconnect — a screen lock, a
    // change of network — replays the expired token, is refused, and every
    // retry after it replays the same dead token. The socket never comes back
    // for the rest of the session while HTTP carries on working.
    _tokenChanges = _tokens.changes.listen((_) => _onTokensChanged());
  }

  final TokenStore _tokens;

  StreamSubscription<void>? _tokenChanges;

  io.Socket? _socket;
  Timer? _heartbeat;

  /// The access token the open socket handshook with, so a change can be told
  /// from a rewrite of the same value.
  String? _authedWith;

  /// Threads to re-join after a reconnect. The server forgets room membership
  /// when a socket drops, so without this a recovered connection would look
  /// alive while receiving nothing.
  final Set<ChatThread> _joined = <ChatThread>{};

  final _messages = StreamController<Map<String, dynamic>>.broadcast();
  final _presence = StreamController<PresenceState>.broadcast();
  final _deliveryLocations = StreamController<Map<String, dynamic>>.broadcast();
  final _typing = StreamController<TypingState>.broadcast();
  final _receipts = StreamController<ReceiptState>.broadcast();
  final _connected = StreamController<bool>.broadcast();
  final _errors = StreamController<String>.broadcast();

  /// A message was stored — by either party, on any of their devices.
  Stream<Map<String, dynamic>> get messages => _messages.stream;
  Stream<PresenceState> get presence => _presence.stream;

  /// Courier positions, as they are reported.
  Stream<Map<String, dynamic>> get deliveryLocations =>
      _deliveryLocations.stream;
  Stream<TypingState> get typing => _typing.stream;
  Stream<ReceiptState> get receipts => _receipts.stream;

  /// Whether the socket is currently up, for the "connecting…" affordance.
  Stream<bool> get connectionState => _connected.stream;

  /// Refusals and connection failures, for a screen that wants to say so.
  Stream<String> get errors => _errors.stream;

  /// Debug-only: a socket log in a release build would be noise, and the
  /// handshake carries a token that has no business in production logs.
  void _log(String message) {
    if (kDebugMode) debugPrint('SocketService: $message');
  }

  bool get isConnected => _socket?.connected ?? false;

  /// How often to refresh the server's presence TTL. Comfortably inside the
  /// 60s expiry, so one missed beat is not read as a disconnect.
  static const Duration _heartbeatInterval = Duration(seconds: 20);

  /// Opens the connection, or does nothing if it is already open.
  ///
  /// Safe to call on every app resume: reconnecting an existing socket would
  /// drop and re-establish for no reason.
  void connect() {
    if (_socket != null) return;

    final token = _tokens.accessToken;
    if (token == null || token.isEmpty) {
      // Not an error — this is the signed-out case — but silence here looks
      // identical to a failed connection, so say which it was.
      _log('not connecting: no access token');
      return;
    }

    _authedWith = token;

    final socket = io.io(
      ApiConstants.baseUrl,
      io.OptionBuilder()
          // Websocket only: the polling fallback would defeat the point, and
          // it is the transport that silently degrades on a bad network.
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionDelay(1000)
          // Backs off to half a minute rather than hammering a server that is
          // down, while still recovering quickly from a brief blip.
          .setReconnectionDelayMax(30000)
          .build(),
    );

    socket
      // Failures are logged rather than swallowed.
      //
      // Without these a socket that never connects is completely silent: no
      // throw, no log, just a chat that quietly never updates. Diagnosing one
      // meant querying presence from a second client to find out whether the
      // app had a connection at all.
      ..onConnectError((error) {
        _log('connect_error: $error');
        _errors.add('$error');
      })
      ..onError((error) => _log('error: $error'))
      ..onReconnectAttempt((attempt) => _log('reconnect attempt $attempt'))
      ..onReconnectFailed((_) => _log('reconnect failed'))
      ..on(SocketEvents.appError, (data) {
        final message = '${_asMap(data)?['message'] ?? 'Request refused'}';
        _log('server refused: $message');
        _errors.add(message);
      })
      ..onConnect((_) {
        _log('connected');
        _connected.add(true);
        // Rooms do not survive a reconnect; re-join everything this session
        // was watching before the drop.
        for (final thread in _joined) {
          socket.emit(SocketEvents.joinThread, thread.payload);
        }
        _startHeartbeat();
      })
      ..onDisconnect((reason) {
        _log('disconnected: $reason');
        _connected.add(false);
        _stopHeartbeat();
      })
      ..on(SocketEvents.messageNew, (data) {
        final map = _asMap(data);
        if (map != null) _messages.add(map);
      })
      ..on(SocketEvents.deliveryLocation, (data) {
        final map = _asMap(data);
        if (map != null) _deliveryLocations.add(map);
      })
      ..on(SocketEvents.presence, (data) {
        final map = _asMap(data);
        if (map != null) _presence.add(PresenceState.fromJson(map));
      })
      ..on(SocketEvents.typing, (data) {
        final map = _asMap(data);
        if (map == null) return;
        _typing.add(
          TypingState(
            thread: ChatThread.fromJson(map) ?? const ChatThread.consultation(''),
            userId: '${map['userId'] ?? ''}',
            isTyping: map['isTyping'] == true,
          ),
        );
      })
      ..on(SocketEvents.messageReacted, (data) {
        final map = _asMap(data);
        if (map != null) _messages.add(map);
      })
      ..on(SocketEvents.messageRead, (data) => _receipt(data, isRead: true))
      ..on(
        SocketEvents.messageDelivered,
        (data) => _receipt(data, isRead: false),
      );

    _socket = socket;
  }

  void _receipt(dynamic data, {required bool isRead}) {
    final map = _asMap(data);
    if (map == null) return;
    final ids = map['messageIds'];
    _receipts.add(
      ReceiptState(
        thread: ChatThread.fromJson(map) ?? const ChatThread.consultation(''),
        messageIds: ids is List ? ids.map((id) => '$id').toList() : const [],
        isRead: isRead,
      ),
    );
  }

  /// Watches one thread. Remembered, so a reconnect restores it.
  void joinThread(ChatThread thread) {
    if (!thread.isLive) return;
    _joined.add(thread);
    _socket?.emit(SocketEvents.joinThread, thread.payload);
  }

  void leaveThread(ChatThread thread) {
    _joined.remove(thread);
    _socket?.emit(SocketEvents.leaveThread, thread.payload);
  }

  /// Sends a message and resolves with the row the server stored.
  ///
  /// [clientId] is the sender's own id for this message: the server keys on it
  /// so a resend after a dropped ack returns the original rather than posting
  /// twice, and the screen uses it to match its optimistic bubble to the
  /// stored row instead of briefly showing both.
  Future<Map<String, dynamic>?> sendMessage({
    required ChatThread thread,
    required String body,
    required String clientId,
    String? attachmentKey,
    Map<String, dynamic>? attachment,
  }) {
    final socket = _socket;
    if (socket == null || !socket.connected) return Future.value(null);

    final completer = Completer<Map<String, dynamic>?>();
    socket.emitWithAck(
      SocketEvents.sendMessage,
      {
        ...thread.payload,
        'body': body,
        'clientId': clientId,
        'attachmentKey': ?attachmentKey,
        'attachment': ?attachment,
      },
      ack: (response) {
        final map = _asMap(response);
        final ok = map?['ok'] == true;
        completer.complete(ok ? _asMap(map?['data']) : null);
      },
    );

    // A socket that accepts the emit but never acks would otherwise leave the
    // caller waiting forever; the screen falls back to HTTP on null.
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );
  }

  /// Sets, replaces or clears a reaction. A null [kind] clears; sending the
  /// kind already set toggles it off server-side.
  void react({
    required ChatThread thread,
    required String messageId,
    required String? kind,
  }) => _socket?.emit(SocketEvents.react, {
    ...thread.payload,
    'messageId': messageId,
    'kind': kind,
  });

  void markRead(ChatThread thread) =>
      _socket?.emit(SocketEvents.markRead, thread.payload);

  void markDelivered(ChatThread thread) =>
      _socket?.emit(SocketEvents.markDelivered, thread.payload);

  void setTyping(ChatThread thread, {required bool isTyping}) => _socket?.emit(
    isTyping ? SocketEvents.typingStart : SocketEvents.typingStop,
    thread.payload,
  );

  /// One-off presence read, for a thread header opening before any change.
  Future<PresenceState?> queryPresence(String userId) {
    final socket = _socket;
    if (socket == null || !socket.connected) return Future.value(null);

    final completer = Completer<PresenceState?>();
    socket.emitWithAck(
      SocketEvents.presenceQuery,
      {'userId': userId},
      ack: (response) {
        final map = _asMap(response);
        final data = map?['ok'] == true ? _asMap(map?['data']) : null;
        completer.complete(data == null ? null : PresenceState.fromJson(data));
      },
    );
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => null,
    );
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeat = Timer.periodic(
      _heartbeatInterval,
      (_) => _socket?.emit(SocketEvents.heartbeat),
    );
  }

  void _stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  /// Re-handshakes with the token that has just replaced the one in use.
  ///
  /// socket.io holds the auth payload it was built with and replays it on
  /// every reconnect, so there is no way to hand it a new token but to build
  /// a new socket. Rooms are restored by `connect`'s own rejoin, which reads
  /// [_joined] — cleared by `disconnect`, so it is saved across the swap.
  void _onTokensChanged() {
    final token = _tokens.accessToken;
    if (token == _authedWith) return;

    // Signed out. `disconnect` is called on that path already; doing it here
    // too is harmless and covers a sign-out that does not go through it.
    if (token == null || token.isEmpty) {
      disconnect();
      return;
    }

    // Nothing to re-authenticate: a socket that was never opened will pick up
    // the new token whenever something connects it.
    if (_socket == null) return;

    _log('access token changed; reconnecting');
    final rejoin = Set<ChatThread>.of(_joined);
    disconnect();
    connect();
    // Restored after `connect`, not before: `disconnect` clears the set. The
    // handshake is asynchronous, so `onConnect` runs well after this and
    // finds the rooms waiting for it.
    _joined.addAll(rejoin);
  }

  /// Drops the connection — on sign-out, or when a role switch means the
  /// token no longer matches the user the socket authenticated as.
  void disconnect() {
    _stopHeartbeat();
    _joined.clear();
    _socket?.dispose();
    _socket = null;
    _authedWith = null;
    _connected.add(false);
  }

  void dispose() {
    _tokenChanges?.cancel();
    _tokenChanges = null;
    disconnect();
    _messages.close();
    _presence.close();
    _deliveryLocations.close();
    _typing.close();
    _receipts.close();
    _connected.close();
    _errors.close();
  }

  static Map<String, dynamic>? _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;
}
