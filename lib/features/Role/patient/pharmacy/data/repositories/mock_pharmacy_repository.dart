import '../../domain/entities/pharmacy.dart';
import '../../domain/repositories/pharmacy_repository.dart';
import '../static/pharmacy_mock_data.dart';

/// In-memory pharmacy data, so the flow is walkable without a server and
/// goldens render a known catalogue.
///
/// Resolves immediately. A simulated network delay only makes a golden race
/// the clock and capture an empty list.
class MockPharmacyRepository implements PharmacyRepository {
  @override
  Future<void> payOrder(String orderId) async {}

  const MockPharmacyRepository();

  @override
  Future<List<Medicine>> searchMedicines({
    String query = '',
    String? pharmacyId,
  }) async {
    final term = query.trim().toLowerCase();
    // A shop's own shelf, which in the demo stocks the demo script — the
    // basket is priced by matching a prescription against the catalogue of
    // whoever is filling it, so a shelf that carries none of it prices
    // everything at zero.
    final all = pharmacyId == null
        ? PharmacyMockData.commonMedicines
        : PharmacyMockData.prescribed;
    if (term.isEmpty) return all;
    return all.where((m) => m.name.toLowerCase().contains(term)).toList();
  }

  @override
  Future<List<PharmacyStore>> stores({String query = ''}) async {
    return PharmacyMockData.nearbyStores;
  }

  @override
  Future<String> placeOrder({
    required String pharmacyId,
    required Map<String, int> quantitiesByMedicineId,
    required String deliveryAddress,
    String? prescriptionId,
  }) async {
    return 'mock-order-1';
  }

  @override
  Future<List<PharmacyOrder>> orders() async {
    return const [];
  }

  /// A short demo run between two Santo Domingo points, so the map has a real
  /// journey to draw without a server.
  @override
  Future<DeliveryRoute> deliveryRoute(String deliveryId) async => DeliveryRoute(
    status: 'in_transit',
    courier: const MapPoint(lat: 18.4801, lng: -69.9215),
    pickup: const MapPoint(lat: 18.4861, lng: -69.9312, label: 'Demo Pharmacy'),
    dropoff: const MapPoint(
      lat: 18.4712,
      lng: -69.9089,
      label: '12 Oak Avenue',
    ),
    reportedAt: DateTime.now(),
  );

  @override
  Future<String?> deliveryIdForOrder(String orderId) async => 'mock-delivery';

  @override
  Future<Courier?> courierFor(String deliveryId) async => const Courier(
    id: 'mock-rider',
    name: 'Demo Courier',
    rating: 4.8,
    reviewCount: 32,
    vehicleType: 'motorbike',
  );

  @override
  Future<double> deliveryCharge() async => 2.50;

  @override
  Future<List<PharmacyStore>> bestMatches(String prescriptionId) async =>
      List.of(PharmacyMockData.matches);
}