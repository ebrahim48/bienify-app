import 'package:bienify_app/core/network/socket_service.dart';
import 'package:bienify_app/core/services/call_service.dart';
import 'package:bienify_app/core/services/ringtone_service.dart';
import 'package:bienify_app/features/Role/patient/appointments/domain/entities/appointment.dart';
import 'dart:async';

import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/routes/app_routes.dart';
import 'package:bienify_app/features/calls/presentation/screens/outgoing_call_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:bienify_app/core/models/chat_thread.dart';
import 'package:bienify_app/features/Role/patient/chat/domain/entities/conversation.dart';
import 'package:bienify_app/features/Role/patient/chat/presentation/controllers/chat_controller.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_call_signalling.dart';

/// Covers the ring: the half of a consultation in front of the video room.
///
/// Before this, a call "started" by one party appearing alone in an Agora
/// channel and the other finding out by opening the app. These assert on what
/// the service actually did — the tone it started, the event it emitted — not
/// that a collaborator was called.
void main() {
  late FakeCallSignalling socket;
  late SilentRingtoneService ringtone;
  late CallService calls;

  /// What the person who tapped Call was actually told.
  late List<String> notices;

  CallEvent incoming({
    String callId = 'call-1',
    String appointmentId = 'appt-1',
    String name = 'Dr Grace',
    Duration? ringsFor,
  }) => CallEvent(
    signal: CallSignal.incoming,
    callId: callId,
    appointmentId: appointmentId,
    from: CallParty(id: 'peer-1', name: name),
    ringsFor: ringsFor,
  );

  setUp(() {
    // Navigation is not what these assert on, and a real navigator would need
    // a widget tree the service does not own.
    Get.testMode = true;
    socket = FakeCallSignalling();
    ringtone = SilentRingtoneService();
    notices = [];
    calls = CallService(
      socket: socket,
      ringtone: ringtone,
      notice: notices.add,
    );
    calls.onInit();
  });

  tearDown(() async {
    calls.onClose();
    await socket.close();
    Get.reset();
  });

  group('an incoming call', () {
    test('rings, and names who is calling', () async {
      socket.deliver(incoming());
      await Future<void>.delayed(Duration.zero);

      expect(calls.phase.value, CallPhase.incoming);
      expect(calls.peer.value?.name, 'Dr Grace');
      // The tone is the whole point: a call that arrives silently is missed.
      expect(ringtone.playing, Ringtone.incoming);
    });

    test('is declined as busy while another call is up', () async {
      socket.deliver(incoming());
      await Future<void>.delayed(Duration.zero);
      socket.sent.clear();

      socket.deliver(incoming(callId: 'call-2', name: 'Someone Else'));
      await Future<void>.delayed(Duration.zero);

      // Declined rather than stacked: a second full screen over a live call
      // leaves the first caller listening to a ringtone nobody will answer.
      expect(socket.sent, contains('decline:call-2:busy'));
      expect(calls.active.value?.callId, 'call-1');
      expect(calls.peer.value?.name, 'Dr Grace');
    });

    test('stops ringing when the caller gives up', () async {
      socket.deliver(incoming());
      await Future<void>.delayed(Duration.zero);

      socket.deliver(
        const CallEvent(signal: CallSignal.cancelled, callId: 'call-1'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(calls.phase.value, CallPhase.idle);
      expect(ringtone.playing, isNull);
      expect(calls.endedReason.value, isNotNull);
    });

    test('ignores an event for a call this device is not on', () async {
      socket.deliver(incoming());
      await Future<void>.delayed(Duration.zero);

      // A stale hang-up for a call that already ended must not tear down the
      // one that replaced it.
      socket.deliver(
        const CallEvent(signal: CallSignal.ended, callId: 'some-old-call'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(calls.phase.value, CallPhase.incoming);
      expect(ringtone.playing, Ringtone.incoming);
    });

    test('gives up on its own clock when the server goes quiet', () async {
      socket.deliver(incoming(ringsFor: const Duration(milliseconds: 40)));
      await Future<void>.delayed(Duration.zero);
      expect(calls.phase.value, CallPhase.incoming);

      // The server times the ring out too, but that notice travels over the
      // socket that may be the very thing that dropped.
      await Future<void>.delayed(const Duration(milliseconds: 90));
      expect(calls.phase.value, CallPhase.idle);
      expect(ringtone.playing, isNull);
    });

    test('accepting asks the server, and waits for it to say so', () async {
      socket.deliver(incoming());
      await Future<void>.delayed(Duration.zero);
      calls.accept();

      expect(socket.sent, contains('accept:call-1'));
      // Not connected yet: the room opens on `call:accepted`, on both devices,
      // so neither can enter one the other never joined.
      expect(calls.phase.value, CallPhase.incoming);

      socket.deliver(
        const CallEvent(
          signal: CallSignal.accepted,
          callId: 'call-1',
          appointmentId: 'appt-1',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(calls.phase.value, CallPhase.connected);
      expect(ringtone.playing, isNull);
    });
  });

  group('an outgoing call', () {
    Appointment appointment() => Appointment(
      id: 'appt-9',
      doctorName: 'Dr Grace',
      specialty: 'Cardiology',
      scheduledAt: DateTime(2026, 8, 31, 10),
    );

    test('rings the consultation and plays the ringback', () async {
      socket.inviteAnswer = const CallEvent(
        signal: CallSignal.accepted,
        callId: 'call-7',
        appointmentId: 'appt-9',
      );

      await calls.ring(appointment());

      expect(socket.sent, contains('invite:appt-9'));
      expect(calls.phase.value, CallPhase.outgoing);
      expect(calls.active.value?.callId, 'call-7');
      expect(ringtone.playing, Ringtone.outgoing);
    });

    test('gives up when the invite could not be placed', () async {
      socket.inviteAnswer = null;

      await calls.ring(appointment());

      // A ringing screen for a call that was never opened is a control that
      // does nothing while looking live.
      expect(calls.phase.value, CallPhase.idle);
      expect(ringtone.playing, isNull);
      expect(calls.endedReason.value, isNotNull);
      expect(notices, isNotEmpty);
    });

    test('repeats the refusal the server gave, not a generic line', () async {
      // The server refuses in words the patient can act on. Only the null ack
      // reached the caller before this, so the reason went to the debug log
      // and the Call button looked like it did nothing at all.
      socket.refuse('Cannot call a consultation that is pending_payment');
      await Future<void>.delayed(Duration.zero);
      socket.inviteAnswer = null;

      await calls.ring(appointment());

      expect(notices, ['Cannot call a consultation that is pending_payment']);
      expect(
        calls.endedReason.value,
        'Cannot call a consultation that is pending_payment',
      );
    });

    test('ignores a refusal left over from an earlier attempt', () async {
      // A refusal from minutes ago belongs to some other call; repeating it
      // would explain this failure with the wrong reason. The window is zero
      // here so anything already received counts as stale.
      final stale = CallService(
        socket: socket,
        ringtone: ringtone,
        notice: notices.add,
        refusalWindow: Duration.zero,
      );
      stale.onInit();
      addTearDown(stale.onClose);

      socket.refuse('Something that already happened');
      await Future<void>.delayed(Duration.zero);
      socket.inviteAnswer = null;

      await stale.ring(appointment());

      expect(notices.single, isNot('Something that already happened'));
    });

    test('answers the crossed invite instead of opening a second call', () async {
      // Both of them tapped call at the same moment; the server hands back the
      // one already ringing.
      socket.inviteAnswer = const CallEvent(
        signal: CallSignal.incoming,
        callId: 'call-theirs',
        appointmentId: 'appt-9',
      );

      await calls.ring(appointment());

      // Two ids for one consultation is how the pair end up in two rooms.
      expect(socket.sent, contains('accept:call-theirs'));
    });

    test('cancelling tells the other side and stops the ringback', () async {
      socket.inviteAnswer = const CallEvent(
        signal: CallSignal.accepted,
        callId: 'call-7',
        appointmentId: 'appt-9',
      );
      await calls.ring(appointment());

      calls.cancel();

      expect(socket.sent, contains('cancel:call-7'));
      expect(calls.phase.value, CallPhase.idle);
      expect(ringtone.playing, isNull);
    });

    test('is refused while this device is already on a call', () async {
      socket.deliver(incoming());
      await Future<void>.delayed(Duration.zero);
      socket.sent.clear();

      await calls.ring(appointment());

      expect(socket.sent, isEmpty);
      expect(calls.active.value?.callId, 'call-1');
    });
  });

  group('the ringing screen', () {
    testWidgets('closes when the invite was refused before it built', (
      tester,
    ) async {
      // The real ordering, which the test below did not have: `ring` pushes
      // this route and *then* awaits the invite, so against a local server the
      // refusal lands before the screen has finished building. `ever` only
      // fires on a change, so that transition happened with nobody listening
      // and the screen stayed up for good — and every button on it was dead,
      // Decline included, because `_finish` returns early once the phase is
      // already idle. A full-screen call the person cannot get out of.
      Get.put<CallService>(calls);
      addTearDown(() => Get.delete<CallService>(force: true));

      tester.view.physicalSize = const Size(390, 876);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 876),
          builder: (context, _) => GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            initialRoute: '/start',
            getPages: [
              GetPage<void>(
                name: '/start',
                page: () => const Scaffold(body: Text('behind')),
              ),
              GetPage<void>(
                name: AppRoutes.outgoingCall,
                page: () => const OutgoingCallScreen(),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No call is ever opened: the server turns the invite down.
      socket.inviteAnswer = null;
      unawaited(
        calls.ring(
          Appointment(
            id: 'appt-9',
            doctorName: 'Dr Grace',
            specialty: 'Cardiology',
            scheduledAt: DateTime(2026, 8, 31, 10),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(calls.phase.value, CallPhase.idle);
      expect(find.byType(OutgoingCallScreen), findsNothing);
      expect(find.text('behind'), findsOneWidget);
    });

    testWidgets('closes itself once the call is over', (tester) async {
      // The service used to pop this by comparing `Get.currentRoute` against a
      // route name, which is a guess about the navigator rather than a fact
      // about the call. When the server refused an invite the comparison did
      // not match, nothing closed, and the caller was left looking at
      // "Connecting…" for a call that had already been turned down.
      Get.put<CallService>(calls);
      addTearDown(() => Get.delete<CallService>(force: true));

      // The call screen sizes itself against the design canvas; on the 800x600
      // default surface its column overflows, which is the viewport's fault
      // and not the widget's.
      tester.view.physicalSize = const Size(390, 876);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 876),
          builder: (context, _) => GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            initialRoute: '/start',
            getPages: [
              GetPage<void>(
                name: '/start',
                page: () => const Scaffold(body: Text('behind')),
              ),
              GetPage<void>(
                name: AppRoutes.outgoingCall,
                page: () => const OutgoingCallScreen(),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      socket.inviteAnswer = const CallEvent(
        signal: CallSignal.accepted,
        callId: 'call-7',
        appointmentId: 'appt-9',
      );
      unawaited(
        calls.ring(
          Appointment(
            id: 'appt-9',
            doctorName: 'Dr Grace',
            specialty: 'Cardiology',
            scheduledAt: DateTime(2026, 8, 31, 10),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OutgoingCallScreen), findsOneWidget);

      // The other side hangs up.
      socket.deliver(
        const CallEvent(signal: CallSignal.ended, callId: 'call-7'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OutgoingCallScreen), findsNothing);
      expect(find.text('behind'), findsOneWidget);
    });
  });

  group('calling from a thread', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await DependencyInjection.init(
        useMocks: true,
        ringtone: SilentRingtoneService(),
      );
      // The app's own `CallService` is replaced with one whose socket a test
      // can read. Everything else the chat controller reaches for — the
      // conversation repository, the picker, the uploader — comes from the
      // mock graph. Deleted first: `Get.put` over a *permanent* registration
      // keeps the original, so without this the controller would go on finding
      // the real service and the test could never fail.
      await Get.delete<CallService>(force: true);
      Get.put<CallService>(calls, permanent: true);
    });

    tearDown(() {
      DependencyInjection.clear();
    });

    ChatController controllerFor(ConversationPeer peer) {
      final controller = ChatController(peer: peer);
      addTearDown(controller.onClose);
      return controller;
    }

    test('a consultation thread can be called into', () {
      final controller = controllerFor(
        const ConversationPeer(
          id: 'doctor-1',
          thread: ChatThread.consultation('appt-3'),
          name: 'Dr Grace',
          specialty: 'Cardiology',
        ),
      );
      expect(controller.canCall, isTrue);

      controller.startVideoCall();
      // The consultation is the call and the conversation both, so the ring
      // goes to the thread the screen is already open on.
      expect(socket.sent, ['invite:appt-3']);
    });

    test('a courier thread cannot', () {
      final controller = controllerFor(
        const ConversationPeer(
          id: 'rider-1',
          thread: ChatThread.delivery('d-1'),
          name: 'Ana',
          specialty: 'Courier',
        ),
      );
      expect(controller.canCall, isFalse);

      controller.startVideoCall();
      // A courier and their customer message; they do not consult. A dialler
      // here would be a control that looks live and does nothing.
      expect(socket.sent, isEmpty);
    });

    test('a thread opened outside any conversation cannot either', () {
      final controller = controllerFor(
        const ConversationPeer(
          id: 'doctor-2',
          name: 'Dr Unbooked',
          specialty: 'Neurology',
        ),
      );
      expect(controller.canCall, isFalse);
    });
  });
}
