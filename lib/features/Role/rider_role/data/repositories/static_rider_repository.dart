import '../../domain/entities/rider.dart';
import '../../domain/repositories/rider_repository.dart';
import '../static/rider_data.dart';

/// The courier, served from the design's sample data.
///
/// Golden and widget tests assert on rendering, so they must not depend on a
/// backend being up. Writes are accepted and dropped — the screens show their
/// own confirmation.
class StaticRiderRepository implements RiderRepository {
  const StaticRiderRepository();

  @override
  Future<Rider> rider() async => RiderData.rider;

  @override
  Future<void> setOnline({required bool isOnline}) async {}

  @override
  Future<List<DeliveryRequest>> requests() async => RiderData.requests();

  @override
  Future<void> claim(String deliveryId) async {}

  @override
  Future<void> setStatus(
    String deliveryId,
    String status, {
    String? reason,
  }) async {}

  @override
  Future<RiderEarnings> earnings() async => RiderData.earnings;

  @override
  Future<void> apply({
    required String vehicleType,
    required String licenceNumber,
    required String city,
  }) async {}

  @override
  Future<void> saveProfile({
    required String vehicleType,
    required String licenceNumber,
    required String city,
  }) async {}
}
