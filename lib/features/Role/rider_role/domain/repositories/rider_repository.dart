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

  Future<void> saveProfile({
    required String vehicleType,
    required String licenceNumber,
    required String city,
  });
}
