import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/call_service.dart';

/// Closes a ringing screen once the call it belongs to is over.
///
/// The service used to pop these itself, when `Get.currentRoute` happened to
/// match one of their route names. That is a guess about the navigator rather
/// than a fact about the call, and it failed exactly when it mattered: a
/// refused invite left the caller on a screen still saying "Connecting…" for a
/// call the server had already turned down. A screen that can see the call is
/// over is the right thing to close it.
///
/// Mixed into both ringing screens, because both have the same job and a
/// second copy of it would drift.
mixin ClosesWithTheCall<T extends StatefulWidget> on State<T> {
  Worker? _watch;

  CallService get calls => Get.find<CallService>();

  @override
  void initState() {
    super.initState();
    _watch = ever<CallPhase>(calls.phase, (_) => _closeIfOver());

    // The call can already be over before this screen has finished building.
    // `ring` pushes the route and *then* awaits the invite, and a refusal
    // comes back in milliseconds — so the phase went to idle with nobody yet
    // listening, `ever` never fired, and the screen stayed up for good. Every
    // button on it then did nothing, Decline included, because `_finish`
    // returns early once the phase is already idle. That is a full-screen call
    // the person cannot get out of, on both devices at once.
    WidgetsBinding.instance.addPostFrameCallback((_) => _closeIfOver());
  }

  void _closeIfOver() {
    if (!mounted) return;
    // `connected` hands over to the video screen, which navigates for itself;
    // only a call that is genuinely finished closes this.
    if (calls.phase.value != CallPhase.idle) return;

    final route = ModalRoute.of(context);
    if (route == null || !route.isActive) return;
    // Removed by identity rather than popped blind. A snackbar route or a
    // sheet opened over the top would otherwise take the pop meant for this
    // screen, and leave the call screen underneath exactly where it was.
    if (route.isCurrent) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).removeRoute(route);
    }
  }

  @override
  void dispose() {
    _watch?.dispose();
    super.dispose();
  }
}
