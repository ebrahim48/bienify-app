import '../../domain/entities/pharmacy.dart';
import '../../domain/repositories/pharmacy_repository.dart';
import '../static/pharmacy_mock_data.dart';

/// In-memory pharmacy data, so the flow is walkable without a server and
/// goldens render a known catalogue.
///
/// Resolves immediately. A simulated network delay only makes a golden race
/// the clock and capture an empty list.
class MockPharmacyRepository implements PharmacyRepository {
  const MockPharmacyRepository();

  @override
  Future<List<Medicine>> searchMedicines({
    String query = '',
    String? pharmacyId,
  }) async {
    final term = query.trim().toLowerCase();
    final all = PharmacyMockData.commonMedicines;
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
}
