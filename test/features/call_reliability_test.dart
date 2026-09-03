// The ways a video consultation used to go wrong.
//
// Each of these is a defect that shipped, not a hypothetical. They are
// gathered in one file because they share a subject — a call that ends up in a
// state one side cannot get out of — and because the cheapest way to keep them
// fixed is to have them fail together the moment any of it regresses.

import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:bienify_app/features/Role/patient/appointments/domain/entities/appointment.dart';
import 'package:bienify_app/core/services/call_service.dart';
import 'package:bienify_app/core/services/incoming_call_notifier.dart';
import 'package:bienify_app/core/services/ringtone_service.dart';
import 'package:bienify_app/core/services/video_call_service.dart';
import 'package:bienify_app/core/network/socket_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../support/fake_call_signalling.dart';

/// Records what the call was announced with, and when it was taken down.
class _Notifier implements IncomingCallNotifier {
  final List<String> shown = [];
  int dismissals = 0;

  @override
  Future<void> show({required String callerName}) async => shown.add(callerName);

  @override
  Future<void> dismiss() async => dismissals += 1;
}

/// An engine that records what the call setup asked of it.
class _Engine implements RtcEngine {
  final List<String> calls = [];

  @override
  Future<void> muteLocalAudioStream(bool mute) async =>
      calls.add('muteAudio:$mute');

  @override
  Future<void> muteLocalVideoStream(bool mute) async =>
      calls.add('muteVideo:$mute');

  @override
  Future<void> stopPreview({
    VideoSourceType sourceType = VideoSourceType.videoSourceCameraPrimary,
  }) async => calls.add('stopPreview');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Appointment _appointment() => Appointment(
  id: 'appt-1',
  doctorName: 'Dr Grace',
  specialty: 'Cardiology',
  scheduledAt: DateTime(2026, 9, 3, 10),
);

void main() {
  late FakeCallSignalling socket;
  late SilentRingtoneService ringtone;
  late _Notifier notifier;
  late CallService calls;
  late List<String> notices;

  setUp(() {
    Get.testMode = true;
    socket = FakeCallSignalling();
    ringtone = SilentRingtoneService();
    notifier = _Notifier();
    notices = [];
    calls = CallService(
      socket: socket,
      ringtone: ringtone,
      notice: notices.add,
      notifier: notifier,
    );
    calls.onInit();
  });

  tearDown(() async {
    calls.onClose();
    await socket.close();
    Get.reset();
  });

  group('cancelling while the invite is still in flight', () {
    test('still calls the other phone off', () async {
      // Cancel read `active`, which is not set until the invite comes back.
      // Tapping Cancel inside that window told the server nothing at all: the
      // other phone rang for the full forty-five seconds and could be
      // answered into a room the caller had already left.
      final gate = Completer<void>();
      socket.inviteGate = gate;
      socket.inviteAnswer = const CallEvent(
        signal: CallSignal.accepted,
        callId: 'call-9',
        appointmentId: 'appt-1',
      );

      final ringing = calls.ring(_appointment());
      await Future<void>.delayed(Duration.zero);

      calls.cancel();
      gate.complete();
      await ringing;

      expect(socket.sent, contains('cancel:call-9'));
      expect(calls.phase.value, CallPhase.idle);
    });

    test('does not leave the service holding a call it cancelled', () async {
      final gate = Completer<void>();
      socket.inviteGate = gate;
      socket.inviteAnswer = const CallEvent(
        signal: CallSignal.accepted,
        callId: 'call-9',
        appointmentId: 'appt-1',
      );

      final ringing = calls.ring(_appointment());
      await Future<void>.delayed(Duration.zero);
      calls.cancel();
      gate.complete();
      await ringing;

      // The stale write used to land `active` on an idle service, which then
      // matched the callee's answer and half-started a call nobody was in.
      expect(calls.active.value, isNull);
    });
  });

  group('the clock both sides count from', () {
    test('is the instant the server recorded the answer', () async {
      final answered = DateTime(2026, 9, 3, 10, 30, 15);
      socket.inviteAnswer = const CallEvent(
        signal: CallSignal.accepted,
        callId: 'call-7',
        appointmentId: 'appt-1',
      );
      await calls.ring(_appointment());

      socket.deliver(
        CallEvent(
          signal: CallSignal.accepted,
          callId: 'call-7',
          appointmentId: 'appt-1',
          answeredAt: answered,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      // Each device used to count its own timer ticks from whenever its own
      // screen appeared, so the two clocks started apart and drifted further
      // every time one was backgrounded and stopped being ticked.
      expect(calls.answeredAt, answered);
    });

    test('falls back to now when the server did not say', () async {
      socket.inviteAnswer = const CallEvent(
        signal: CallSignal.accepted,
        callId: 'call-7',
        appointmentId: 'appt-1',
      );
      await calls.ring(_appointment());

      socket.deliver(
        const CallEvent(
          signal: CallSignal.accepted,
          callId: 'call-7',
          appointmentId: 'appt-1',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(calls.answeredAt, isNotNull);
    });

    test('is let go of when the call ends', () async {
      socket.inviteAnswer = const CallEvent(
        signal: CallSignal.accepted,
        callId: 'call-7',
        appointmentId: 'appt-1',
      );
      await calls.ring(_appointment());
      socket.deliver(
        const CallEvent(
          signal: CallSignal.accepted,
          callId: 'call-7',
          appointmentId: 'appt-1',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      calls.hangUp();

      expect(calls.answeredAt, isNull);
    });
  });

  group('announcing the call to the phone, not just to the app', () {
    test('raises it when a call comes in', () async {
      socket.deliver(
        const CallEvent(
          signal: CallSignal.incoming,
          callId: 'call-1',
          appointmentId: 'appt-1',
          from: CallParty(id: 'peer-1', name: 'Ebrahim'),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      // The in-app screen alone is invisible from a pocket: it was pushed
      // behind the launcher and the callee found out afterwards.
      expect(notifier.shown, ['Ebrahim']);
    });

    test('takes it down when the call is answered', () async {
      socket.deliver(
        const CallEvent(
          signal: CallSignal.incoming,
          callId: 'call-1',
          appointmentId: 'appt-1',
          from: CallParty(id: 'peer-1', name: 'Ebrahim'),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      notifier.dismissals = 0;

      socket.deliver(
        const CallEvent(
          signal: CallSignal.accepted,
          callId: 'call-1',
          appointmentId: 'appt-1',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(notifier.dismissals, greaterThan(0));
    });

    test('takes it down when the call ends without being answered', () async {
      socket.deliver(
        const CallEvent(
          signal: CallSignal.incoming,
          callId: 'call-1',
          appointmentId: 'appt-1',
          from: CallParty(id: 'peer-1', name: 'Ebrahim'),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      notifier.dismissals = 0;

      socket.deliver(
        const CallEvent(
          signal: CallSignal.cancelled,
          callId: 'call-1',
          appointmentId: 'appt-1',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      // A ring left on the lock screen for a call that is over is worse than
      // no ring at all.
      expect(notifier.dismissals, greaterThan(0));
    });
  });

  group('a mute chosen before the engine existed', () {
    test('is applied once there is an engine to apply it to', () async {
      // The privacy one. The buttons are live from the first frame and the
      // engine is not, so muting while the screen read "Connecting…" showed a
      // mic-off icon and published anyway.
      final engine = _Engine();

      await applyPendingMedia(engine, muted: true, cameraOff: false);

      expect(engine.calls, contains('muteAudio:true'));
    });

    test('so is a camera turned off early', () async {
      final engine = _Engine();

      await applyPendingMedia(engine, muted: false, cameraOff: true);

      expect(engine.calls, containsAll(<String>['muteVideo:true', 'stopPreview']));
    });

    test('and nothing is touched when nothing was chosen', () async {
      final engine = _Engine();

      await applyPendingMedia(engine, muted: false, cameraOff: false);

      // The join already publishes both tracks; re-asserting them here would
      // undo a mute applied by any other route.
      expect(engine.calls, isEmpty);
    });
  });
}
