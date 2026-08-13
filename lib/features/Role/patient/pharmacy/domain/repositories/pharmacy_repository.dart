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

  /// Pays for a placed order out of the patient's wallet.
  ///
  /// Until this is called the order sits in `pending_payment`, where the
  /// pharmacy is shown it as new but the server refuses to let them accept
  /// it — so an unpaid order is a dead end on both sides.
  Future<void> payOrder(String orderId);

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
