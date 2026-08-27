import '../../../patient/pharmacy/domain/entities/pharmacy.dart';
import '../entities/rider.dart';

/// Everything the courier's screens read and write.
abstract class RiderRepository {
  /// The courier — masthead, today's figures, and the details behind the
  /// profile.
  Future<Rider> rider();

  /// Whether the courier is accepting work.
  Future<void> setOnline({required bool isOnline});

  /// Jobs going spare, plus the ones this courier already holds.
  Future<List<DeliveryRequest>> requests();

  /// Takes a job off the board.
  Future<void> claim(String deliveryId);

  /// Moves a job along: picked up, in transit, delivered.
  Future<void> setStatus(String deliveryId, String status, {String? reason});

  Future<RiderEarnings> earnings();

  /// Applies to ride for Bienify.
  Future<void> apply({
    required String vehicleType,
    required String licenceNumber,
    required String city,
  });

  /// Files one application document.
  ///
  /// The application screen captures five photos and, until the upload-url
  /// endpoint existed, had nowhere to put them: `POST /riders/me/documents`
  /// wants a key under the courier's own prefix and nothing issued one, so a
  /// courier completed the whole flow and none of their documents arrived.
  Future<void> uploadDocument({
    required String kind,
    required String path,
    required String mimeType,
    void Function(double progress)? onProgress,
  });

  /// Saves the whole edit form.
  ///
  /// It used to take three fields while the screen collected seven, so a
  /// courier changed their name, country, address, zones or location sharing,
  /// was told "Rider updated", and lost all of it on reload.
  Future<void> saveProfile({
    required String vehicleType,
    required String licenceNumber,
    required String city,
    String? name,
    String? country,
    String? addressLine,
    List<String>? zones,
    bool? shareLiveLocation,
  });

  /// The route for a job the courier is on — `GET /deliveries/:id/location`.
  ///
  /// The same read the customer's map uses; a courier is a participant on
  /// their own delivery. Their map drew two constants before, so every job
  /// showed the same road whatever they were actually carrying.
  Future<DeliveryRoute> route(String deliveryId);
}
