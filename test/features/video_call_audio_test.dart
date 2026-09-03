// Audio on a video consultation.
//
// The engine setup configured video and never mentioned sound: no audio
// module, no audio route. The Communication profile a consultation joins with
// sends audio to the *earpiece* by default — right for a phone call held
// against your head, wrong for a video call held at arm's length. The sound
// was coming out of a speaker nobody's ear was near, which is indistinguishable
// from a call with no audio.
//
// None of this was reachable by a test, because the settings were inline in a
// method that builds a real Agora engine. They are a function now, and this is
// what that function is for.

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:bienify_app/core/services/video_call_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what the call setup asked of the engine, in order.
class _Engine implements RtcEngine {
  final List<String> calls = [];

  /// What the audio route was last set to, or null if it was never set.
  bool? speakerphone;

  @override
  Future<void> enableVideo() async => calls.add('enableVideo');

  @override
  Future<void> enableAudio() async => calls.add('enableAudio');

  @override
  Future<void> setDefaultAudioRouteToSpeakerphone(bool defaultToSpeaker) async {
    calls.add('setDefaultAudioRouteToSpeakerphone');
    speakerphone = defaultToSpeaker;
  }

  @override
  Future<void> startPreview({
    VideoSourceType sourceType = VideoSourceType.videoSourceCameraPrimary,
  }) async => calls.add('startPreview');

  // Everything else an `RtcEngine` can do is beside the point here.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Engine engine;

  setUp(() => engine = _Engine());

  test('turns the audio module on', () async {
    await configureForVideoConsultation(engine);

    expect(engine.calls, contains('enableAudio'));
  });

  test('sends the audio to the loudspeaker, not the earpiece', () async {
    await configureForVideoConsultation(engine);

    // The one that actually silenced calls. Without it Agora's Communication
    // profile routes to the earpiece, and a consultation held at arm's length
    // has nobody near that speaker.
    expect(engine.speakerphone, isTrue);
  });

  test('turns the video module on and starts the preview', () async {
    await configureForVideoConsultation(engine);

    expect(engine.calls, containsAll(<String>['enableVideo', 'startPreview']));
  });

  group('what each side publishes and subscribes to', () {
    test('publishes the microphone', () async {
      // Without this a consultation is a silent film: both sides connected,
      // both seeing each other, neither heard.
      expect(consultationMediaOptions.publishMicrophoneTrack, isTrue);
    });

    test('subscribes to the other side automatically', () async {
      expect(consultationMediaOptions.autoSubscribeAudio, isTrue);
    });

    test('publishes and subscribes to video too', () async {
      expect(consultationMediaOptions.publishCameraTrack, isTrue);
      expect(consultationMediaOptions.autoSubscribeVideo, isTrue);
    });

    test('joins as a broadcaster, not an audience member', () async {
      // An audience member may not publish at all, which would silence this
      // side however the tracks above are set.
      expect(
        consultationMediaOptions.clientRoleType,
        ClientRoleType.clientRoleBroadcaster,
      );
    });
  });

  test('configures both before the preview starts', () async {
    await configureForVideoConsultation(engine);

    // Settings applied after the preview is running are not reliably picked
    // up, so the order is part of the behaviour rather than incidental.
    expect(
      engine.calls.indexOf('startPreview'),
      greaterThan(engine.calls.indexOf('enableAudio')),
    );
    expect(
      engine.calls.indexOf('startPreview'),
      greaterThan(engine.calls.indexOf('setDefaultAudioRouteToSpeakerphone')),
    );
  });
}
