import 'package:geolocator/geolocator.dart';

/// One fix, on demand.
///
/// Separate from the courier's `RiderLocationReporter`, which streams a
/// position for a whole delivery: this is for a patient standing at their own
/// door pinning it once. Both ask the same permissions, so the refusal
/// messages read the same way.
class DeviceLocationService {
  /// The fix, or null with a reason when there is none.
  ///
  /// Returning the reason rather than throwing keeps the caller's happy path
  /// clean while still letting the screen say *why* — "location is off" and
  /// "you said no" need different words, and a bare null gives neither.
  Future<({double lat, double lng})?> currentPosition({
    void Function(DeviceLocationRefusal reason)? onRefused,
  }) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      onRefused?.call(DeviceLocationRefusal.serviceOff);
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      onRefused?.call(DeviceLocationRefusal.denied);
      return null;
    }
    if (permission == LocationPermission.deniedForever) {
      onRefused?.call(DeviceLocationRefusal.blocked);
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return (lat: position.latitude, lng: position.longitude);
    } catch (_) {
      // No fix yet — indoors, or the receiver is still warming up. Saying so
      // beats storing a stale or invented coordinate.
      onRefused?.call(DeviceLocationRefusal.noFix);
      return null;
    }
  }
}

/// Why there is no position. Each one needs different words, and one of them
/// (blocked) needs the patient to go to Settings rather than tap again.
enum DeviceLocationRefusal { serviceOff, denied, blocked, noFix }
