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

  /// Everything waiting for me, in every thread. Sent on connect: a message
  /// that arrived while this client was offline has nobody to report it.
  static const String markAllDelivered = 'message:delivered:all';
  static const String react = 'message:react';
  static const String edit = 'message:edit';
  static const String typingStart = 'typing:start';
  static const String typingStop = 'typing:stop';
  static const String heartbeat = 'presence:heartbeat';
  static const String presenceQuery = 'presence:query';

  /// Ringing. Signalling only — the video room itself is still opened over
  /// HTTP, so a call nobody answers never creates a channel.
  static const String callInvite = 'call:invite';
  static const String callAccept = 'call:accept';
  static const String callDecline = 'call:decline';
  static const String callCancel = 'call:cancel';
  static const String callEnd = 'call:end';

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
  static const String messageEdited = 'message:edited';
  static const String typing = 'typing';
  static const String presence = 'presence';
  static const String callIncoming = 'call:incoming';
  static const String callAccepted = 'call:accepted';
  static const String callDeclined = 'call:declined';
  static const String callCancelled = 'call:cancelled';
  static const String callEnded = 'call:ended';
  static const String callUnanswered = 'call:unanswered';
  /// Something the signed-in person should be told about, as the in-app
  /// feed lists it.
  static const String notificationNew = 'notification:new';
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
    // `.toLocal()` for the same reason `Api.date` does it: the server sends
    // UTC, and "last seen 14:32" read off a UTC `DateTime` is someone else's
    // clock.
    lastSeen: json['lastSeen'] == null
        ? null
        : DateTime.tryParse('${json['lastSeen']}')?.toLocal(),
  );

  final String userId;
  final bool isOnline;
  final DateTime? lastSeen;
}

/// What the server said about a call.
///
/// One type for every `call:*` the server sends, because the screens care
/// about the same three fields whichever arrived and the difference is carried
/// by [signal]. Five near-identical classes was the alternative, and the
/// screens would still have had to switch over them.
enum CallSignal {
  /// Somebody is ringing this device.
  incoming,

  /// Answered — both sides enter the room.
  accepted,

  /// The callee refused.
  declined,

  /// The caller hung up before it was answered.
  cancelled,

  /// A connected call was hung up.
  ended,

  /// The ring expired with nobody picking up.
  unanswered,
}

/// Who is calling, as the full-screen shows them.
class CallParty {
  const CallParty({required this.id, required this.name, this.avatarUrl});

  factory CallParty.fromJson(Map<String, dynamic> json) => CallParty(
    id: '${json['id'] ?? ''}',
    name: '${json['name'] ?? ''}',
    avatarUrl: json['avatarUrl']?.toString(),
  );

  final String id;
  final String name;
  final String? avatarUrl;
}

/// A call event, as it arrived.
class CallEvent {
  const CallEvent({
    required this.signal,
    required this.callId,
    this.appointmentId = '',
    this.from,
    this.reason,
    this.ringsFor,
    this.answeredAt,
  });

  factory CallEvent.fromJson(CallSignal signal, Map<String, dynamic> json) {
    final from = json['from'];
    final expiry = json['expiresInMs'];
    return CallEvent(
      signal: signal,
      callId: '${json['callId'] ?? ''}',
      appointmentId: '${json['appointmentId'] ?? ''}',
      from: from is Map
          ? CallParty.fromJson(Map<String, dynamic>.from(from))
          : null,
      reason: json['reason']?.toString(),
      ringsFor: expiry is num
          ? Duration(milliseconds: expiry.toInt())
          : null,
      // When the call was answered, decided by the server. Both devices count
      // from this one instant instead of from whenever their own screen
      // happened to appear.
      answeredAt: json['answeredAt'] == null
          ? null
          : DateTime.tryParse('${json['answeredAt']}')?.toLocal(),
    );
  }

  final CallSignal signal;

  /// The instant the server recorded the call as answered, on this device's
  /// clock. Null on every signal but `accepted`.
  final DateTime? answeredAt;
  final String callId;

  /// The consultation the call is on — the id the video room is opened with.
  final String appointmentId;

  /// The caller. Only carried by [CallSignal.incoming].
  final CallParty? from;

  final String? reason;

  /// How long the server will let this ring. The client stops on its own
  /// clock too, so a lost `call:unanswered` cannot leave a phone ringing.
  final Duration? ringsFor;

  /// True for anything that means this call is over.
  bool get isOver =>
      signal == CallSignal.declined ||
      signal == CallSignal.cancelled ||
      signal == CallSignal.ended ||
      signal == CallSignal.unanswered;
}

/// The half of the socket a call needs.
///
/// Narrow on purpose. `CallService` is driven entirely by these six members,
/// so a test can supply its own without standing up a websocket — and without
/// the alternative, which was a `@visibleForTesting` back door on the real
/// service for pushing events into its own stream.
abstract class CallSignalling {
  Stream<CallEvent> get calls;

  /// Refusals, in the server's own words.
  ///
  /// Needed because a refused invite comes back only as a null ack, which
  /// cannot say *why*. Nothing in the app listened to this stream at all, so
  /// "Cannot call a consultation that is pending_payment" reached the debug
  /// log and the caller saw a call button that did nothing.
  Stream<String> get errors;

  /// Rings the other party in a consultation. Null when the socket is down or
  /// the server refused.
  Future<CallEvent?> inviteToCall(String appointmentId);

  void acceptCall(String callId);
  void declineCall(String callId, {String reason});
  void cancelCall(String callId);
  void endCall(String callId);
}

/// The half of the socket the notification inbox needs.
///
/// Narrow for the same reason [CallSignalling] is: the inbox is driven by this
/// one member, so a test can supply its own without standing up a websocket —
/// and without a `@visibleForTesting` back door on the real service for
/// pushing events into its own stream.
abstract class NotificationFeed {
  /// Notifications as the server publishes them, rather than when the feed is
  /// next re-read.
  Stream<Map<String, dynamic>> get notifications;
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
class SocketService implements CallSignalling, NotificationFeed {
  SocketService({
    required TokenStore tokens,
    Future<void> Function()? refreshTokens,
    this.renewalCooldown = const Duration(seconds: 30),
  }) : _tokens = tokens,
       _refreshTokens = refreshTokens {
    // A refresh replaces the access token this socket authenticated with.
    // Without this the handshake credential silently rots: the connection
    // already open keeps working, but the next reconnect — a screen lock, a
    // change of network — replays the expired token, is refused, and every
    // retry after it replays the same dead token. The socket never comes back
    // for the rest of the session while HTTP carries on working.
    _tokenChanges = _tokens.changes.listen((_) => _onTokensChanged());
  }

  final TokenStore _tokens;

  /// Renews the access token when the handshake is refused for having a dead
  /// one. Null in tests and wherever there is nothing to refresh through.
  final Future<void> Function()? _refreshTokens;

  /// True while a refusal is being recovered from, so a burst of failing
  /// reconnect attempts asks for one refresh rather than one each. The backend
  /// treats a replayed refresh token as theft and revokes every session for
  /// that user, so this guard is not merely tidy.
  bool _recovering = false;

  /// Set while a renewal is too recent to be worth repeating.
  ///
  /// Cleared on a successful connect, and otherwise on a timer. Only clearing
  /// it on connect looked right and was the original bug wearing a new hat: if
  /// the reconnect straight after a renewal happened to fail — and it can, the
  /// old socket is still tearing down — nothing would ever ask for a token
  /// again, and the session stayed silently dead exactly as before.
  bool _renewedRecently = false;
  Timer? _renewalCooldown;

  /// Long enough that a burst of refused retries spends one refresh, short
  /// enough that a token expiring later in the session is still recoverable.
  final Duration renewalCooldown;

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
  final _edits = StreamController<Map<String, dynamic>>.broadcast();
  final _presence = StreamController<PresenceState>.broadcast();
  final _deliveryLocations = StreamController<Map<String, dynamic>>.broadcast();
  final _typing = StreamController<TypingState>.broadcast();
  final _receipts = StreamController<ReceiptState>.broadcast();
  final _connected = StreamController<bool>.broadcast();
  final _calls = StreamController<CallEvent>.broadcast();
  final _notifications = StreamController<Map<String, dynamic>>.broadcast();
  final _errors = StreamController<String>.broadcast();

  /// A message was stored — by either party, on any of their devices.
  Stream<Map<String, dynamic>> get messages => _messages.stream;

  /// Messages whose text the sender rewrote, as the whole message.
  Stream<Map<String, dynamic>> get edits => _edits.stream;
  Stream<PresenceState> get presence => _presence.stream;

  /// Courier positions, as they are reported.
  Stream<Map<String, dynamic>> get deliveryLocations =>
      _deliveryLocations.stream;
  Stream<TypingState> get typing => _typing.stream;
  Stream<ReceiptState> get receipts => _receipts.stream;

  /// Whether the socket is currently up, for the "connecting…" affordance.
  Stream<bool> get connectionState => _connected.stream;

  /// Ringing, answering and hanging up — every `call:*` the server sends.
  @override
  Stream<CallEvent> get calls => _calls.stream;

  /// Notifications as they happen, rather than when the feed is next re-read.
  ///
  /// The list was pull-to-refresh only, so a doctor reviewing a result said
  /// nothing to a patient sitting on the open app.
  @override
  Stream<Map<String, dynamic>> get notifications => _notifications.stream;

  /// Refusals and connection failures, for a screen that wants to say so.
  @override
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
          // A manager of its own, every time.
          //
          // socket.io-client caches its manager per URL and `dispose()` tears
          // that manager down. Every path that rebuilds this socket — a token
          // renewal, a sign-in as somebody else — disposes and calls `io()`
          // again, which handed the new socket the destroyed manager: it never
          // connected and never even retried, so nothing was logged and the
          // app sat there looking connected with no connection at all. It is
          // why renewing the access token appeared not to help.
          .enableForceNew()
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
        handleConnectError('$error');
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
        _renewedRecently = false;
        _renewalCooldown?.cancel();
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
      ..on(SocketEvents.messageEdited, (data) {
        final map = _asMap(data);
        // Its own stream, not `messages`: a thread list watching for arrivals
        // would read a rewrite as a new message, count it unread and pull the
        // conversation to the top for words that were already there.
        if (map != null) _edits.add(map);
      })
      ..on(
        SocketEvents.callIncoming,
        (data) => _call(CallSignal.incoming, data),
      )
      ..on(
        SocketEvents.callAccepted,
        (data) => _call(CallSignal.accepted, data),
      )
      ..on(
        SocketEvents.callDeclined,
        (data) => _call(CallSignal.declined, data),
      )
      ..on(
        SocketEvents.callCancelled,
        (data) => _call(CallSignal.cancelled, data),
      )
      ..on(SocketEvents.callEnded, (data) => _call(CallSignal.ended, data))
      ..on(
        SocketEvents.callUnanswered,
        (data) => _call(CallSignal.unanswered, data),
      )
      ..on(SocketEvents.notificationNew, (data) {
        final map = _asMap(data);
        if (map != null) _notifications.add(map);
      })
      ..on(SocketEvents.messageRead, (data) => _receipt(data, isRead: true))
      ..on(
        SocketEvents.messageDelivered,
        (data) => _receipt(data, isRead: false),
      );

    _socket = socket;
  }

  void _call(CallSignal signal, dynamic data) {
    final map = _asMap(data);
    if (map != null) _calls.add(CallEvent.fromJson(signal, map));
  }

  /// Rings the other party in a consultation.
  ///
  /// Resolves with the call the server opened, or null when the socket is
  /// down or the server refused — a caller that cannot ring must be told so
  /// rather than shown a ringing screen for a call nobody will ever receive.
  ///
  /// `alreadyRinging` comes back when the other party rang first and the two
  /// invites crossed: the answer is to pick that call up, not to open a
  /// second one, which would put the two of them in different rooms.
  @override
  Future<CallEvent?> inviteToCall(String appointmentId) {
    final socket = _socket;
    if (socket == null || !socket.connected) return Future.value(null);

    final completer = Completer<CallEvent?>();
    socket.emitWithAck(
      SocketEvents.callInvite,
      {'appointmentId': appointmentId},
      ack: (response) {
        final map = _asMap(response);
        final data = map?['ok'] == true ? _asMap(map?['data']) : null;
        completer.complete(
          data == null
              ? null
              : CallEvent.fromJson(
                  data['alreadyRinging'] == true
                      ? CallSignal.incoming
                      : CallSignal.accepted,
                  {...data, 'appointmentId': appointmentId},
                ),
        );
      },
    );
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );
  }

  @override
  void acceptCall(String callId) =>
      _socket?.emit(SocketEvents.callAccept, {'callId': callId});

  @override
  void declineCall(String callId, {String reason = 'declined'}) =>
      _socket?.emit(SocketEvents.callDecline, {
        'callId': callId,
        'reason': reason,
      });

  @override
  void cancelCall(String callId) =>
      _socket?.emit(SocketEvents.callCancel, {'callId': callId});

  @override
  void endCall(String callId) =>
      _socket?.emit(SocketEvents.callEnd, {'callId': callId});

  /// How the socket answers a refused or failed handshake.
  ///
  /// The entry point `onConnectError` calls, and the one the tests drive —
  /// this is the socket's response to a real transport event, not a hook that
  /// exists for them.
  ///
  /// Gets a fresh access token and reconnects when the handshake was refused
  /// because the one it carried had expired.
  ///
  /// The access token lives fifteen minutes. socket.io holds the auth payload
  /// it was built with and replays it on every reconnect, so once that token
  /// expired the first drop — a screen lock, a change of network, a laptop
  /// waking up — was refused, and every retry afterwards replayed the same
  /// dead token. The socket never came back for the rest of the session while
  /// HTTP carried on working, because the auth interceptor refreshes on a 401
  /// and a client sitting in a chat makes no requests to get a 401 from.
  ///
  /// The visible symptom was not "the socket is down": it was messages not
  /// arriving, the other side never being marked as having read anything, and
  /// presence frozen — on a screen that looked entirely connected.
  void handleConnectError(String error) {
    if (!isAuthFailure(error)) return;
    if (_recovering || _renewedRecently) return;

    final refresh = _refreshTokens;
    if (refresh == null) return;

    _recovering = true;
    _renewedRecently = true;
    _renewalCooldown?.cancel();
    _renewalCooldown = Timer(renewalCooldown, () {
      _renewedRecently = false;
    });
    _log('handshake refused; renewing the access token');

    unawaited(
      refresh()
          .then((_) {
            // `save` fires `TokenStore.changes`, which rebuilds the socket with
            // the new token. If the token came back unchanged — nothing to
            // renew — reconnect anyway so a transient refusal is not fatal.
            if (_tokens.accessToken == _authedWith) _reconnect();
          })
          .catchError((Object err) {
            // A refresh token that is spent or revoked. Sign-out is the auth
            // layer's to handle; there is nothing for the socket to do but
            // stop asking.
            _log('token renewal failed: $err');
          })
          .whenComplete(() => _recovering = false),
    );
  }

  /// Whether the server refused the handshake over credentials rather than
  /// being unreachable. Matched on the wording `authenticate` sends, because a
  /// timeout must not spend a refresh token — the backend treats a replayed
  /// one as theft and revokes every session for that user.
  static bool isAuthFailure(String error) {
    final message = error.toLowerCase();
    return message.contains('access token');
  }

  /// Rebuilds the socket with whatever token is current, keeping the rooms.
  void _reconnect() {
    final rejoin = Set<ChatThread>.of(_joined);
    disconnect();
    connect();
    // Restored after `connect`, since `disconnect` clears the set. The
    // handshake is asynchronous, so `onConnect` runs well after this and finds
    // the rooms waiting for it.
    _joined.addAll(rejoin);
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

  /// Rewrites the body of a message this user sent.
  ///
  /// The server is the one that decides whether it still may be: this side's
  /// window check only keeps the option off a bubble that would be refused.
  void editMessage({
    required ChatThread thread,
    required String messageId,
    required String body,
  }) => _socket?.emit(SocketEvents.edit, {
    ...thread.payload,
    'messageId': messageId,
    'body': body,
  });

  void markRead(ChatThread thread) =>
      _socket?.emit(SocketEvents.markRead, thread.payload);

  void markDelivered(ChatThread thread) =>
      _socket?.emit(SocketEvents.markDelivered, thread.payload);

  /// Reports the whole backlog as delivered — every thread, in one call.
  ///
  /// Sent whenever the connection comes up. Delivered means this device is
  /// reachable and holding the message, and coming online is exactly when
  /// that becomes true for everything sent while it was not.
  void markAllDelivered() => _socket?.emit(SocketEvents.markAllDelivered);

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
    _reconnect();
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
    _renewalCooldown?.cancel();
    _renewalCooldown = null;
    _tokenChanges?.cancel();
    _tokenChanges = null;
    disconnect();
    _messages.close();
    _edits.close();
    _presence.close();
    _deliveryLocations.close();
    _typing.close();
    _receipts.close();
    _calls.close();
    _notifications.close();
    _connected.close();
    _errors.close();
  }

  static Map<String, dynamic>? _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;
}
