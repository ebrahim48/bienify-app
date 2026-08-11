import '../entities/pharmacy.dart';

/// Browsing medicines, choosing a pharmacy and placing an order.
abstract class PharmacyRepository {
  /// The catalogue, optionally narrowed by [query] or to one [pharmacyId].
  Future<List<Medicine>> searchMedicines({String query, String? pharmacyId});

  /// Pharmacies that can fulfil an order.
  Future<List<PharmacyStore>> stores({String query});

  /// Places an order and returns its id.
  ///
  /// [prescriptionId] is required for anything the catalogue marks as
  /// prescription-only; the server refuses the order without it rather than
  /// trusting the client to have checked.
  Future<String> placeOrder({
    required String pharmacyId,
    required Map<String, int> quantitiesByMedicineId,
    required String deliveryAddress,
    String? prescriptionId,
  });

  /// The patient's orders, newest first.
  Future<List<PharmacyOrder>> orders();
}

/// An order the patient has placed.
class PharmacyOrder {
  const PharmacyOrder({
    required this.id,
    required this.lines,
    required this.total,
    required this.status,
    required this.placedAt,
    this.deliveryAddress = '',
  });

  final String id;
  final List<CartLine> lines;
  final double total;

  /// The server's own status string — the tracking screen maps it to a step.
  final String status;
  final DateTime placedAt;
  final String deliveryAddress;
}
