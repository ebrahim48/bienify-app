import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../../core/exceptions/app_exceptions.dart';
import '../../domain/repositories/rider_repository.dart';

/// Reports the courier's position while they are carrying a parcel.
///
/// This is the half of live tracking that was missing. `PATCH
/// /deliveries/:id/location` has existed since the delivery module was
/// written, `GET /deliveries/:id/location` reads what it stores, and the
/// customer's map subscribes to the `delivery:location` socket event the
/// server pushes on every write — but nothing in the app ever called the
/// write. So `lastLocation` stayed null for every delivery ever made, the
/// customer's map drew a route with no courier on it, and the courier's own
/// map showed a pin that only moved when the screen was reopened.
///
/// Positions come from the device rather than a timer over a straight line:
/// an interpolated pin is an invented one, and a customer watching it would be
/// told where the courier is not.
class RiderLocationReporter {
  RiderLocationReporter(this._repository);

  final RiderRepository _repository;

  StreamSubscription<Position>? _positions;

  /// The job being reported on, so a second `start` for the same delivery does
  /// not tear down a working stream and build it again.
  String? _deliveryId;

  /// The last position that reached the server, published for the courier's
  /// own map so their pin moves with them between reads.
  final _reported = StreamController<Position>.broadcast();

  Stream<Position> get reported => _reported.stream;

  bool get isRunning => _positions != null;

  /// How far the courier must move before a new position is sent.
  ///
  /// A parcel on a motorbike passes this in a couple of seconds, and a courier
  /// waiting at a light sends nothing at all — which is the point. A fixed
  /// interval would spend the phone's battery and the server's writes on a
  /// stationary rider.
  static const int _metres = 15;

  /// How the device is asked for positions.
  ///
  /// On Android this is an `AndroidSettings` carrying a foreground-service
  /// notification, which is what keeps positions arriving after the courier
  /// locks their phone or switches app. Without it Android throttles a
  /// backgrounded app to a few updates an hour, so the courier froze on the
  /// customer's map the moment the screen went off — the one moment they are
  /// most obviously moving.
  ///
  /// The notification is not decoration: Android requires a visible one for
  /// background location, and a courier is entitled to see that their position
  /// is being shared.
  static LocationSettings _settings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _metres,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Sharing your location',
          notificationText: 'Your customer can see where you are',
          enableWakeLock: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _metres,
        allowBackgroundLocationUpdates: true,
        // The blue bar is how iOS tells the courier they are being located, and
        // hiding it would be doing this behind their back.
        showBackgroundLocationIndicator: true,
        pauseLocationUpdatesAutomatically: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: _metres,
    );
  }

  /// Begins reporting for [deliveryId].
  ///
  /// Returns why it could not start, or null when it did. The caller decides
  /// whether that is worth a message: a courier who has declined location once
  /// should not be asked again at every screen.
  Future<String?> start(String deliveryId) async {
    if (_deliveryId == deliveryId && isRunning) return null;
    await stop();

    try {
      return await _start(deliveryId);
    } catch (_) {
      // No location implementation on this platform — a desktop build, or a
      // test. The parcel is still deliverable without a pin, so this reports
      // rather than throws into the screen that opened it.
      await stop();
      return null;
    }
  }

  Future<String?> _start(String deliveryId) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return 'Turn on location to share your position with the customer';
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return 'Location permission is needed to share your position';
    }
    if (permission == LocationPermission.deniedForever) {
      return 'Location is blocked for this app in Settings';
    }

    _deliveryId = deliveryId;
    _positions =
        Geolocator.getPositionStream(
          locationSettings: _settings(),
        ).listen(
          _send,
          // A GPS stream that errors — the receiver dropping out, a permission
          // revoked mid-job — must not take the delivery down with it. The
          // courier keeps the parcel; only the pin goes stale.
          onError: (_) {},
        );

    // The stream's first event waits for the courier to move, so a job opened
    // while standing at the pharmacy would report nothing at all until they
    // set off. One position now gives the customer a pin immediately.
    await _sendCurrent();
    return null;
  }

  Future<void> _sendCurrent() async {
    try {
      await _send(
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ),
      );
    } catch (_) {
      // No fix yet. The stream will carry the first one that arrives.
    }
  }

  Future<void> _send(Position position) async {
    final id = _deliveryId;
    if (id == null) return;
    try {
      await _repository.reportLocation(id, position.latitude, position.longitude);
      _reported.add(position);
    } on ForbiddenException {
      // The courier has turned live location sharing off, or no longer holds
      // this parcel. Either way the server will refuse every position from
      // here on, so the stream is shut down rather than left draining the
      // battery on writes that cannot land.
      await stop();
    } on AppException {
      // A dropped ping costs one position, not the stream: the next one is
      // seconds away, and the server refuses positions on a parcel that has
      // arrived — which [stop] handles, but a race with it is not an error
      // worth showing a courier mid-ride.
    }
  }

  Future<void> stop() async {
    await _positions?.cancel();
    _positions = null;
    _deliveryId = null;
  }

  Future<void> dispose() async {
    await stop();
    await _reported.close();
  }
}
