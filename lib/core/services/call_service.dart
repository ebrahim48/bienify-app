import 'incoming_call_notifier.dart';
import 'dart:async';

import 'package:get/get.dart';

import '../../features/Role/patient/appointments/domain/entities/appointment.dart';
import '../../features/Role/patient/auth/data/datasources/auth_local_data_source.dart';
import '../../features/Role/patient/auth/domain/entities/user_role.dart';
import '../constants/app_strings.dart';
import '../network/socket_service.dart';
import '../routes/app_routes.dart';
import '../widgets/app_snackbar.dart';
import 'ringtone_service.dart';

/// Where a call has got to on *this* device.
enum CallPhase {
  idle,

  /// Somebody is ringing us; the full screen is up and the tone is playing.
  incoming,

  /// We are ringing somebody and waiting for them to pick up.
  outgoing,

  /// Answered. The video screen owns it from here.
  connected,
}

/// The ring, everywhere in the app.
///
/// Registered permanently and listening from sign-in, because a call has to
/// arrive on whatever screen its recipient happens to be looking at — which is
/// exactly the thing a screen-scoped controller cannot do. Before this, a
/// consultation "started" by the caller appearing alone in an Agora channel;
/// the other party found out by opening the app and looking at their bookings.
///
/// Deliberately signalling only. It decides *whether* two people are about to
/// be in a room together and hands off to `VideoCallController` for the media,
/// so a call nobody answers never opens a channel.
class CallService extends GetxService {
  CallService({
    required CallSignalling socket,
    required RingtoneService ringtone,
    AuthLocalDataSource? auth,
    void Function(String message)? notice,
    IncomingCallNotifier? notifier,
    this.refusalWindow = const Duration(seconds: 15),
  }) : _socket = socket,
       _ringtone = ringtone,
       _auth = auth,
       _notifier = notifier ?? SilentIncomingCallNotifier(),
       _notice = notice ?? AppSnackbar.info;

  final CallSignalling _socket;

  /// Raises the call over whatever else is on the phone, when the app is not
  /// the thing on screen. The in-app screen alone is invisible from a pocket.
  final IncomingCallNotifier _notifier;
  final RingtoneService _ringtone;
  final AuthLocalDataSource? _auth;

  /// How a refusal reaches the person who tapped Call. Injectable so a test
  /// can read what was said without standing up a snackbar overlay.
  final void Function(String message) _notice;

  /// How recent a refusal must be to be shown against the call that just
  /// failed. A refusal from minutes ago belongs to some other attempt, and
  /// repeating it would explain this failure with the wrong reason.
  final Duration refusalWindow;

  final Rx<CallPhase> phase = CallPhase.idle.obs;

  /// The call this device is in, ringing or connected. Null when idle.
  final Rxn<CallEvent> active = Rxn<CallEvent>();

  /// The other party as the ringing screens draw them — a name and a face,
  /// because a call screen showing a bare id is a wrong number.
  final Rxn<CallParty> peer = Rxn<CallParty>();

  /// When the call was answered, as the server saw it.
  ///
  /// Held here rather than on the call screen because both sides need the same
  /// origin: each used to count its own timer ticks from whenever its own
  /// screen appeared, so the two clocks started apart and drifted further
  /// every time one device was backgrounded and stopped being ticked.
  DateTime? answeredAt;

  /// Why the last call ended, for the line the screen prints on its way out.
  final RxnString endedReason = RxnString();

  StreamSubscription<CallEvent>? _events;
  StreamSubscription<String>? _refusals;

  /// The last thing the server refused, and when.
  ///
  /// A refused invite comes back as a null ack, which cannot say why — the
  /// reason arrives separately on the error stream. Kept with its arrival time
  /// so a stale refusal from minutes ago is not shown against this call.
  String? _lastRefusal;
  DateTime? _lastRefusalAt;

  /// Stops ringing when the server's own timeout notice is lost — the phone
  /// must not keep ringing because a socket dropped mid-ring.
  Timer? _ringExpiry;

  /// What the callee joins. Built from the invite rather than fetched: the
  /// video screen needs a name and an appointment id, and both are in it.
  Appointment? _joining;

  @override
  void onInit() {
    super.onInit();
    _events = _socket.calls.listen(_onEvent);
    _refusals = _socket.errors.listen((message) {
      _lastRefusal = message;
      _lastRefusalAt = DateTime.now();
    });
  }

  @override
  void onClose() {
    _ringExpiry?.cancel();
    unawaited(_events?.cancel());
    unawaited(_refusals?.cancel());
    unawaited(_ringtone.dispose());
    super.onClose();
  }

  bool get isBusy => phase.value != CallPhase.idle;

  /// The call screen for whoever is signed in. The two are the same screen
  /// with the role flipped; only where the call ends differs.
  String get _callRoute => _auth?.readSession()?.user.role == UserRole.doctor
      ? AppRoutes.doctorVideoCall
      : AppRoutes.videoCall;

  // ─── Outgoing ────────────────────────────────────────────────────────────

  /// Rings the other party in [appointment].
  ///
  /// Shows the ringing screen first and emits after, so a tap is acknowledged
  /// immediately rather than after a socket round trip — and so a refusal has
  /// somewhere to be shown. A failed invite tears the screen back down instead
  /// of leaving a ringing display for a call that was never opened.
  Future<void> ring(Appointment appointment, {CallParty? callee}) async {
    if (isBusy) return;

    _joining = appointment;
    peer.value =
        callee ??
        CallParty(
          id: appointment.doctorUserId,
          name: appointment.doctorName,
          avatarUrl: appointment.doctorPhotoUrl,
        );
    phase.value = CallPhase.outgoing;
    endedReason.value = null;
    unawaited(_ringtone.start(Ringtone.outgoing));
    Get.toNamed<void>(AppRoutes.outgoingCall);

    final opened = await _socket.inviteToCall(appointment.id);
    if (opened == null) {
      // The server's own words when it has just given them — "Cannot call a
      // consultation that is pending_payment" tells the patient what to do
      // about it, where "Could not place the call" does not.
      _finish(reason: _refusalReason(), translated: true);
      return;
    }

    // Cancelled while the invite was still in flight. `cancel` had nothing to
    // cancel — `active` was still null — so it closed this screen and told the
    // server nothing: the other phone rang on for the full forty-five seconds
    // and could be answered into a room the caller had already left. The call
    // is known now, so it can be called off properly.
    if (phase.value == CallPhase.idle) {
      _socket.cancelCall(opened.callId);
      return;
    }

    active.value = opened;

    // The two of them tapped call at the same moment and the invites crossed.
    // Answering theirs is the only way both end up in one room; opening a
    // second call would put them in two.
    if (opened.signal == CallSignal.incoming) {
      _socket.acceptCall(opened.callId);
      return;
    }

    // A call that is already live rather than ringing: this invite joined an
    // existing session instead of opening one. Arming the ring expiry anyway
    // is what stops the caller sitting on "Ringing…" forever for a call the
    // server considers answered and will never ring again.
    _armRingExpiry(opened.ringsFor);
  }

  /// Gives up on a call that has not been answered.
  void cancel() {
    final call = active.value;
    if (call != null) _socket.cancelCall(call.callId);
    _finish();
  }

  // ─── Incoming ────────────────────────────────────────────────────────────

  /// Picks up. The server answers with `call:accepted`, which is what actually
  /// opens the room — on both devices, so neither can enter one the other
  /// never joined.
  void accept() {
    final call = active.value;
    if (call == null || phase.value != CallPhase.incoming) return;
    _socket.acceptCall(call.callId);
  }

  void decline() {
    final call = active.value;
    if (call != null) _socket.declineCall(call.callId);
    _finish();
  }

  /// Hangs up a connected call. The video screen ends the media itself; this
  /// tells the other side.
  void hangUp() {
    final call = active.value;
    if (call != null) _socket.endCall(call.callId);
    _finish();
  }

  // ─── Server events ───────────────────────────────────────────────────────

  void _onEvent(CallEvent event) {
    switch (event.signal) {
      case CallSignal.incoming:
        _onIncoming(event);
      case CallSignal.accepted:
        _onAccepted(event);
      case CallSignal.declined:
      case CallSignal.cancelled:
      case CallSignal.ended:
      case CallSignal.unanswered:
        // Only the call this device is actually in. A stale event for a call
        // that already ended must not tear down the one that replaced it.
        if (active.value?.callId != event.callId) return;
        _finish(reason: _reasonFor(event));
    }
  }

  void _onIncoming(CallEvent event) {
    // Already on a call. Declining is the honest answer — the alternative is a
    // second full screen over a live consultation, and a caller left listening
    // to a ringtone nobody is ever going to answer.
    if (isBusy) {
      _socket.declineCall(event.callId, reason: 'busy');
      return;
    }

    active.value = event;
    peer.value = event.from;
    phase.value = CallPhase.incoming;
    unawaited(_notifier.show(callerName: event.from?.name ?? ''));
    endedReason.value = null;
    _joining = Appointment(
      id: event.appointmentId,
      // The call screen reads an `Appointment`, so the caller is mapped onto
      // one — the same mapping the doctor's own call binding already makes.
      doctorName: event.from?.name ?? '',
      specialty: '',
      scheduledAt: DateTime.now(),
      doctorPhotoUrl: event.from?.avatarUrl,
    );

    unawaited(_ringtone.start(Ringtone.incoming));
    _armRingExpiry(event.ringsFor);
    Get.toNamed<void>(AppRoutes.incomingCall);
  }

  void _onAccepted(CallEvent event) {
    if (active.value?.callId != event.callId) return;

    _ringExpiry?.cancel();
    phase.value = CallPhase.connected;
    // The server's instant, so both devices count the call from the same
    // moment. Falls back to now only if an older server did not send one.
    answeredAt = event.answeredAt ?? DateTime.now();
    unawaited(_ringtone.stop());
    unawaited(_notifier.dismiss());

    final appointment = _joining;
    if (appointment == null) {
      _finish();
      return;
    }

    // `offNamed`, so Back from the call does not return to a ringing screen
    // for a call that has already been answered.
    Get.offNamed<void>(_callRoute, arguments: appointment);
  }

  /// A refusal that arrived while this invite was in flight, or the generic
  /// line when the socket simply never answered.
  String _refusalReason() {
    final at = _lastRefusalAt;
    final message = _lastRefusal;
    if (message != null &&
        at != null &&
        DateTime.now().difference(at) < refusalWindow) {
      return message;
    }
    return AppStrings.callFailed.tr;
  }

  String? _reasonFor(CallEvent event) => switch (event.signal) {
    CallSignal.declined => AppStrings.callDeclined,
    CallSignal.cancelled => AppStrings.callCancelled,
    CallSignal.unanswered => AppStrings.callUnanswered,
    _ => null,
  };

  /// Stops ringing on this device's own clock.
  ///
  /// The server also times the ring out and says so, but that notice travels
  /// over the socket that may be the very thing that dropped. A phone left
  /// ringing for a call that ended is worse than one that gives up a second
  /// early, so both clocks run.
  /// Used when the server does not say how long it will ring for.
  ///
  /// It always does for a fresh invite. It does not when the invite joined a
  /// call that was already live, and returning early there left the caller on
  /// "Ringing…" with no expiry, no server ring timer — it was cleared when the
  /// call was answered — and no way out but the back button.
  static const Duration _assumedRingTimeout = Duration(seconds: 45);

  void _armRingExpiry(Duration? within) {
    _ringExpiry?.cancel();
    _ringExpiry = Timer(within ?? _assumedRingTimeout, () {
      if (phase.value == CallPhase.incoming ||
          phase.value == CallPhase.outgoing) {
        _finish(reason: AppStrings.callUnanswered);
      }
    });
  }

  /// Returns to idle, once, however the call ended.
  ///
  /// Guarded on the phase because both sides can arrive together — a local
  /// hang-up and the peer's `call:ended` crossing — and popping twice would
  /// take a screen the call never opened.
  void _finish({String? reason, bool translated = false}) {
    if (phase.value == CallPhase.idle) return;

    _ringExpiry?.cancel();
    _ringExpiry = null;
    phase.value = CallPhase.idle;
    active.value = null;
    peer.value = null;
    answeredAt = null;
    _joining = null;
    // Translated here rather than at each call site so every path out of a
    // call says something, including the ones that used to end in silence.
    final message = reason == null
        ? null
        : (translated ? reason : reason.tr);
    endedReason.value = message;
    unawaited(_ringtone.stop());
    unawaited(_notifier.dismiss());

    // A call that ends for a reason has to say so. The refusal used to reach
    // the debug log alone, so the Call button looked like a control that did
    // nothing at all.
    if (message != null) _notice(message);

    // The ringing screens close themselves by watching [phase].
    //
    // This used to pop from here when `Get.currentRoute` matched one of their
    // route names, which is a guess about the navigator rather than a fact
    // about the call: when the server refused an invite the comparison did not
    // match, nothing popped, and the caller was left on a screen that said
    // "Connecting…" for a call that had already been refused. A screen that
    // knows the call is over is the thing that should close it.
  }
}
