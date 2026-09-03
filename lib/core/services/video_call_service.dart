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

/// What each side publishes and subscribes to for a consultation.
///
/// Said out loud rather than left to the SDK's defaults. These four are the
/// whole of a consultation — being heard, being seen, hearing, and seeing —
/// and the join used to name none of them. The defaults happen to be these
/// values, which is exactly the problem: nothing in the code said a doctor and
/// a patient must be able to hear each other, so nothing here contradicted an
/// audio route that sent the sound to the earpiece.
const ChannelMediaOptions consultationMediaOptions = ChannelMediaOptions(
  clientRoleType: ClientRoleType.clientRoleBroadcaster,
  channelProfile: ChannelProfileType.channelProfileCommunication,
  publishMicrophoneTrack: true,
  publishCameraTrack: true,
  autoSubscribeAudio: true,
  autoSubscribeVideo: true,
);

/// Re-applies a mute or camera-off chosen before the engine existed.
///
/// Its own function so it can be driven against a fake engine, because this
/// is the one worth proving: the buttons are live from the first frame, the
/// engine is not, and `_engine?.mute…` on a null engine did nothing and said
/// nothing about it. Someone who muted themselves while the screen still read
/// "Connecting…" watched a mic-off icon while being published, live, to the
/// other party for the whole consultation.
///
/// Called after the join, because joining republishes both tracks.
Future<void> applyPendingMedia(
  RtcEngine engine, {
  required bool muted,
  required bool cameraOff,
}) async {
  if (muted) await engine.muteLocalAudioStream(true);
  if (cameraOff) {
    await engine.muteLocalVideoStream(true);
    await engine.stopPreview();
  }
}

/// The media settings a video consultation needs, before anyone joins.
///
/// Its own function so it can be driven against a fake engine. Left inline it
/// was unreachable by any test, which is how it went out with audio never
/// configured at all — the engine was told about video and left to its own
/// devices about sound.
///
/// Two things here, and both read to the person holding the phone as "the
/// call has no audio":
///
///   - the audio module is enabled explicitly rather than assumed;
///   - the route is forced to the loudspeaker. The Communication profile a
///     consultation joins with sends audio to the *earpiece* by default,
///     which is right for a phone call held against your head and wrong for a
///     video call held at arm's length. The sound was there all along, coming
///     out of a speaker nobody's ear was near.
Future<void> configureForVideoConsultation(RtcEngine engine) async {
  await engine.enableVideo();
  await engine.enableAudio();
  await engine.setDefaultAudioRouteToSpeakerphone(true);
  await engine.startPreview();
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

  /// The handler this service registered, so it can take it off again.
  RtcEngineEventHandler? _handler;

  /// A release still running from the call before this one.
  static Future<void>? _releasing;

  Future<void> _start(RoomCredentials credentials) async {
    // Agora hands back one engine for the whole process and quietly skips
    // `initialize` if it already exists, so a second call opened while the
    // first was still tearing down attached itself to an engine that was
    // about to be destroyed. Waiting for that to finish is the difference
    // between a working second call and a black screen until restart.
    await _releasing;

    final engine = createAgoraRtcEngine();
    _engine = engine;

    final channel = credentials.roomId;

    await engine.initialize(RtcEngineContext(appId: credentials.appId));
    final handler = RtcEngineEventHandler(
        onJoinChannelSuccess: (_, _) => _emit(
          CallState(stage: CallStage.waiting, channelId: channel),
        ),
        onUserJoined: (_, remoteUid, _) => _peerBack(
          remoteUid,
          channel,
        ),
        // Why they left decides whether the call is over. Hanging up ends it
        // for both sides, the way a phone call works; a network drop does not,
        // because they may be seconds from coming back.
        onUserOffline: (_, _, reason) {
          if (reason == UserOfflineReasonType.userOfflineQuit) {
            _lostPeerAt = null;
            _emit(CallState(stage: CallStage.ended, channelId: channel));
            return;
          }
          // Dropped rather than hung up: their network went, or their phone
          // did. Worth waiting a moment — people walk into lifts — but not
          // forever, which is what this used to do. A dead peer left the other
          // side on "Ringing…" with the timer running and no way out but the
          // back button, which does not hang up either.
          _lostPeerAt = DateTime.now();
          _emit(CallState(stage: CallStage.waiting, channelId: channel));
          _armPeerGiveUp(channel);
        },
        // An error during a call that is already running is not the end of
        // the call. Agora reports plenty of them — a codec fallback, a
        // transient network complaint — and treating every one as fatal tore
        // down the remote video view for good: `failed` carried no
        // `remoteUid`, no further `onUserJoined` was coming for a peer already
        // in the room, and the footer dropped back to "Ringing…" with no way
        // out of a call that was, in fact, still connected.
        onError: (err, msg) {
          if (_state.stage == CallStage.live) return;
          _emit(
            CallState(
              stage: CallStage.failed,
              message: '$err: $msg',
              channelId: channel,
            ),
          );
        },
    );
    _handler = handler;
    engine.registerEventHandler(handler);

    await configureForVideoConsultation(engine);
    // By account, not by uid: the server signs these tokens for a string user
    // account, and Agora answers a numeric-uid join with errInvalidToken.
    await engine.joinChannelWithUserAccount(
      token: credentials.token,
      channelId: credentials.roomId,
      userAccount: credentials.account,
      options: consultationMediaOptions,
    );

    // After the join, because the join republishes both tracks.
    await _applyPendingMedia(engine);
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


  /// How long the other side may be gone before the call is given up on.
  ///
  /// Long enough to survive a lift or a network handover, short enough that a
  /// phone that has died does not leave somebody staring at a frozen screen.
  static const Duration _peerGracePeriod = Duration(seconds: 30);

  DateTime? _lostPeerAt;
  Timer? _peerGiveUp;

  /// The other side came back, or arrived for the first time.
  void _peerBack(int remoteUid, String channel) {
    _lostPeerAt = null;
    _peerGiveUp?.cancel();
    _peerGiveUp = null;
    _emit(
      CallState(stage: CallStage.live, remoteUid: remoteUid, channelId: channel),
    );
  }

  /// Ends the call if the other side does not come back.
  void _armPeerGiveUp(String channel) {
    _peerGiveUp?.cancel();
    _peerGiveUp = Timer(_peerGracePeriod, () {
      if (_lostPeerAt == null) return;
      _emit(CallState(stage: CallStage.ended, channelId: channel));
    });
  }

  Future<bool> _grantMediaPermissions() async {
    final results = await [Permission.camera, Permission.microphone].request();
    return results.values.every((status) => status.isGranted);
  }

  /// What the user asked for before there was an engine to ask.
  ///
  /// The mute and camera buttons are live from the first frame, while the
  /// engine does not exist until permissions have been granted and the room
  /// has been fetched — a second or two later. `_engine?.mute…` on a null
  /// engine did nothing at all and said nothing about it, so someone who
  /// muted themselves while the screen still read "Connecting…" watched a
  /// mic-off icon while being published, live, to the other party for the
  /// whole consultation. Held here and applied the moment the engine exists.
  bool _wantsMuted = false;
  bool _wantsCameraOff = false;

  @override
  Future<void> setMuted(bool value) async {
    _wantsMuted = value;
    await _engine?.muteLocalAudioStream(value);
  }

  @override
  Future<void> setCameraOff(bool value) async {
    _wantsCameraOff = value;
    final engine = _engine;
    if (engine == null) return;
    await engine.muteLocalVideoStream(value);
    if (value) {
      await engine.stopPreview();
    } else {
      await engine.startPreview();
    }
  }

  /// Applies anything the user chose before the engine was up.
  Future<void> _applyPendingMedia(RtcEngine engine) =>
      applyPendingMedia(engine, muted: _wantsMuted, cameraOff: _wantsCameraOff);

  @override
  Future<void> switchCamera() async => _engine?.switchCamera();

  /// The engine, for the two video views to render through. Null before the
  /// call connects.
  @override
  RtcEngine? get engine => _engine;

  @override
  Future<void> dispose() {
    // Published so the next call can await it. `dispose` is fired and
    // forgotten by the screen that is closing, which is fine — as long as
    // whoever starts the next call knows there is a teardown in flight.
    final done = _dispose();
    _releasing = done;
    return done;
  }

  Future<void> _dispose() async {
    _peerGiveUp?.cancel();
    _peerGiveUp = null;
    _renewal?.cancel();
    _renewal = null;

    final engine = _engine;
    final handler = _handler;
    _engine = null;
    _handler = null;
    if (engine != null) {
      // Unregistered explicitly. `registerEventHandler` adds rather than
      // replaces, so a handler left behind by a finished call goes on
      // receiving events from the shared engine and delivering them into a
      // service nobody is listening to any more.
      if (handler != null) engine.unregisterEventHandler(handler);
      await engine.leaveChannel();
      await engine.release();
    }

    // `_releasing` is deliberately left pointing at this future rather than
    // cleared: awaiting one that has already completed costs nothing, and
    // clearing it could wipe out a newer teardown that started meanwhile.

    await _states.close();
  }
}
