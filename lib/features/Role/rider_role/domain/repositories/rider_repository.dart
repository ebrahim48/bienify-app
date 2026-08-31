import '../../../doctor_role/domain/entities/doctor_practice.dart' show PayoutAccount;
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

  /// Reports where the courier is — `PATCH /deliveries/:id/location`.
  ///
  /// The other half of [route], and the one that was missing: the endpoint has
  /// always existed and no rider code called it, so `lastLocation` was never
  /// written and the customer's live map had no courier pin to draw. The
  /// server pushes each ping on to the patient and the shop over the socket.
  Future<void> reportLocation(String deliveryId, double lat, double lng);

  // ─── Payout ──────────────────────────────────────────────────────────────
  //
  // The courier is paid into the same wallet a doctor is, through the same
  // endpoints. None of it was reachable from the rider's screens.

  /// Where the courier can be paid — `GET /wallet/payout-accounts`.
  Future<List<PayoutAccount>> payoutAccounts();

  /// Files a new destination. The server keeps only the last four digits.
  Future<void> addPayoutAccount({
    required String kind,
    required String displayName,
    required String accountNumber,
    String? bankName,
  });

  Future<void> makePayoutAccountDefault(String accountId);

  /// Asks for a payout — `POST /wallet/withdrawals`.
  ///
  /// [payoutAccountId] is required rather than optional: the server's schema
  /// insists on it, so a request without one is a 400 the courier cannot act
  /// on.
  Future<void> requestWithdrawal({
    required double amount,
    required String payoutAccountId,
  });
}
