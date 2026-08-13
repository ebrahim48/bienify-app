import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../network/mappers.dart';

/// What the server hands back to let one person into one call.
///
/// The app holds no Agora credentials of its own: both the App ID and the
/// channel token come from `POST /consultations/:id/join`, so rotating the
/// Agora project is a backend change rather than an app release.
class RoomCredentials {
  const RoomCredentials({
    required this.appId,
    required this.roomId,
    required this.token,
    required this.expiresAt,
    required this.account,
  });

  factory RoomCredentials.fromJson(Map<String, dynamic> json) =>
      RoomCredentials(
        appId: Api.str(json['appId']),
        roomId: Api.str(json['roomId']),
        token: Api.str(json['token']),
        expiresAt: Api.date(json['expiresAt']),
        account: Api.str(json['account']),
      );

  final String appId;

  /// The Agora channel name.
  final String roomId;

  final String token;
  final DateTime expiresAt;

  /// The identity the token is signed for. The join has to use this exact
  /// string — Agora rejects a token presented under any other.
  final String account;

  bool get isUsable =>
      appId.isNotEmpty && roomId.isNotEmpty && account.isNotEmpty;
}

/// How far the call has got.
enum CallStage {
  idle,
  requestingPermissions,
  connecting,
  waiting,
  live,
  /// The other party hung up. The call is over for this side too.
  ended,
  failed,
}

/// The live consultation, as the call screen needs to see it.
class CallState {
  const CallState({
    this.stage = CallStage.idle,
    this.remoteUid,
    this.message = '',
    this.channelId = '',
  });

  final CallStage stage;

  /// The other party, once they arrive. Null while the call is one-sided.
  final int? remoteUid;

  /// Why the call failed, when it did.
  final String message;

  /// The Agora channel. A remote view has to name the connection it renders
  /// from, so the screen needs this alongside the uid.
  final String channelId;

  bool get hasRemote => remoteUid != null;
}

/// Getting two people into a call and back out again.
///
/// An interface so the call screen can be built and rendered without a video
/// platform behind it — the widget tests draw it with a fake, which no amount
/// of mocking a concrete Agora engine would allow.
abstract class VideoCallService {
  Stream<CallState> get states;

  CallState get state;

  /// The engine the two video views render through. Null before the call
  /// connects, and for any implementation with no engine at all.
  RtcEngine? get engine;

  Future<void> join(String appointmentId);

  Future<void> setMuted(bool value);

  Future<void> setCameraOff(bool value);

  Future<void> switchCamera();

  Future<void> dispose();
}

/// Drives one Agora call.
///
/// Owns the engine and nothing else: it does not know what a consultation is,
/// only how to get two people into a channel and back out again. The
/// controller above it decides when.
class AgoraVideoCallService implements VideoCallService {
  AgoraVideoCallService(this._api);

  final ApiClient _api;

  RtcEngine? _engine;
  Timer? _renewal;

  /// Renew this far before the token actually dies, so a slow request cannot
  /// let it lapse mid-sentence.
  static const Duration _renewalMargin = Duration(minutes: 2);

  final StreamController<CallState> _states =
      StreamController<CallState>.broadcast();

  @override
  Stream<CallState> get states => _states.stream;

  CallState _state = const CallState();

  @override
  CallState get state => _state;

  void _emit(CallState next) {
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }

  /// Joins the call for [appointmentId].
  ///
  /// Permissions first: Agora will happily join a channel with no camera
  /// grant and publish a black frame, which looks like a broken call rather
  /// than a refused permission.
  @override
  Future<void> join(String appointmentId) async {
    _emit(const CallState(stage: CallStage.requestingPermissions));

    final granted = await _grantMediaPermissions();
    if (!granted) {
      _emit(
        const CallState(
          stage: CallStage.failed,
          message: 'Camera and microphone access are needed for a video call.',
        ),
      );
      return;
    }

    _emit(const CallState(stage: CallStage.connecting));

    final RoomCredentials credentials;
    try {
      credentials = await _fetchCredentials(
        ApiConstants.postConsultationsJoin(appointmentId),
      );
    } catch (e) {
      _emit(CallState(stage: CallStage.failed, message: e.toString()));
      return;
    }

    if (!credentials.isUsable) {
      _emit(
        const CallState(
          stage: CallStage.failed,
          message: 'This consultation has no video room configured.',
        ),
      );
      return;
    }

    try {
      await _start(credentials);
    } catch (e) {
      _emit(CallState(stage: CallStage.failed, message: e.toString()));
      return;
    }

    _scheduleRenewal(appointmentId, credentials.expiresAt);
  }

  Future<void> _start(RoomCredentials credentials) async {
    final engine = createAgoraRtcEngine();
    _engine = engine;

    final channel = credentials.roomId;

    await engine.initialize(RtcEngineContext(appId: credentials.appId));
    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (_, _) => _emit(
          CallState(stage: CallStage.waiting, channelId: channel),
        ),
        onUserJoined: (_, remoteUid, _) => _emit(
          CallState(
            stage: CallStage.live,
            remoteUid: remoteUid,
            channelId: channel,
          ),
        ),
        // Why they left decides whether the call is over. Hanging up ends it
        // for both sides, the way a phone call works; a network drop does not,
        // because they may be seconds from coming back.
        onUserOffline: (_, _, reason) => _emit(
          CallState(
            stage: reason == UserOfflineReasonType.userOfflineQuit
                ? CallStage.ended
                : CallStage.waiting,
            channelId: channel,
          ),
        ),
        onError: (err, msg) => _emit(
          CallState(
            stage: CallStage.failed,
            message: '$err: $msg',
            channelId: channel,
          ),
        ),
      ),
    );

    await engine.enableVideo();
    await engine.startPreview();
    // By account, not by uid: the server signs these tokens for a string user
    // account, and Agora answers a numeric-uid join with errInvalidToken.
    await engine.joinChannelWithUserAccount(
      token: credentials.token,
      channelId: credentials.roomId,
      userAccount: credentials.account,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
  }

  /// Swaps in a fresh token before the current one expires.
  void _scheduleRenewal(String appointmentId, DateTime expiresAt) {
    _renewal?.cancel();

    final due = expiresAt.difference(DateTime.now()) - _renewalMargin;
    if (due.isNegative) return;

    _renewal = Timer(due, () async {
      try {
        final next = await _fetchCredentials(
          ApiConstants.postConsultationsToken(appointmentId),
        );
        await _engine?.renewToken(next.token);
        _scheduleRenewal(appointmentId, next.expiresAt);
      } catch (_) {
        // A failed renewal is not worth ending a working call over: the
        // current token is still valid for the margin above, and the next
        // attempt is one interval away.
        _scheduleRenewal(
          appointmentId,
          DateTime.now().add(_renewalMargin * 2),
        );
      }
    });
  }

  Future<RoomCredentials> _fetchCredentials(String path) async {
    final body = Api.map(await _api.post(path));
    // `/join` wraps the credentials beside the consultation; `/token` returns
    // them bare.
    final raw = body.containsKey('credentials')
        ? Api.map(body['credentials'])
        : body;
    return RoomCredentials.fromJson(raw);
  }

  Future<bool> _grantMediaPermissions() async {
    final results = await [Permission.camera, Permission.microphone].request();
    return results.values.every((status) => status.isGranted);
  }

  @override
  Future<void> setMuted(bool value) async =>
      _engine?.muteLocalAudioStream(value);

  @override
  Future<void> setCameraOff(bool value) async {
    await _engine?.muteLocalVideoStream(value);
    if (value) {
      await _engine?.stopPreview();
    } else {
      await _engine?.startPreview();
    }
  }

  @override
  Future<void> switchCamera() async => _engine?.switchCamera();

  /// The engine, for the two video views to render through. Null before the
  /// call connects.
  @override
  RtcEngine? get engine => _engine;

  @override
  Future<void> dispose() async {
    _renewal?.cancel();
    _renewal = null;

    final engine = _engine;
    _engine = null;
    if (engine != null) {
      await engine.leaveChannel();
      await engine.release();
    }

    await _states.close();
  }
}
