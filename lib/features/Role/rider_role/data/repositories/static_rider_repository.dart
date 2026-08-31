import '../../../doctor_role/domain/entities/doctor_practice.dart' show PayoutAccount;
import '../../../patient/pharmacy/domain/entities/pharmacy.dart';
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
    String? name,
    String? country,
    String? addressLine,
    List<String>? zones,
    bool? shareLiveLocation,
  }) async {}

  @override
  Future<void> uploadDocument({
    required String kind,
    required String path,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(1);
  }

  @override
  Future<DeliveryRoute> route(String deliveryId) async => DeliveryRoute(
    status: 'in_transit',
    courier: const MapPoint(lat: 18.4801, lng: -69.9215),
    pickup: const MapPoint(lat: 18.4861, lng: -69.9312, label: 'Demo Pharmacy'),
    dropoff: const MapPoint(lat: 18.4712, lng: -69.9089, label: '12 Oak Avenue'),
    reportedAt: DateTime.now(),
  );

  @override
  Future<void> reportLocation(String deliveryId, double lat, double lng) async {
    // Nowhere to report to without a server. Accepted silently so a courier
    // walking the app offline is not told their position failed to send.
  }

  /// No payout destinations without a server.
  ///
  /// Empty rather than a sample bank account: the payout sheet reads this to
  /// decide whether it can offer a withdrawal at all, and inventing an account
  /// would draw a live-looking button that pays into nothing.
  @override
  Future<List<PayoutAccount>> payoutAccounts() async => const [];

  @override
  Future<void> addPayoutAccount({
    required String kind,
    required String displayName,
    required String accountNumber,
    String? bankName,
  }) async {}

  @override
  Future<void> makePayoutAccountDefault(String accountId) async {}

  @override
  Future<void> requestWithdrawal({
    required double amount,
    required String payoutAccountId,
  }) async {}
}