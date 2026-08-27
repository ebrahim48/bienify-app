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

  /// The live route for one delivery — `GET /deliveries/:id/location`.
  Future<DeliveryRoute> deliveryRoute(String deliveryId);

  /// The delivery dispatched for an order, or null while there is none.
  Future<String?> deliveryIdForOrder(String orderId);

  /// The courier carrying a delivery, once one has taken it.
  Future<Courier?> courierFor(String deliveryId);

  /// What the platform charges to deliver, in major units.
  Future<double> deliveryCharge();

  /// Shops ranked by how much of a prescription they can actually dispense —
  /// `GET /pharmacies/best-matches`.
  ///
  /// Needs a prescription the server knows about, which means one a doctor
  /// issued. A photograph of a paper script is a vault document, not a
  /// prescription, so that path has no id to rank against.
  Future<List<PharmacyStore>> bestMatches(String prescriptionId);
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
    this.pharmacyName = '',
    this.deliveryFee = 0,
  });

  final String id;
  final List<CartLine> lines;
  final double total;

  /// The server's own status string — the tracking screen maps it to a step.
  final String status;
  final DateTime placedAt;
  final String deliveryAddress;

  /// Who is filling it. The timeline used to name one demo pharmacy on every
  /// patient's order.
  final String pharmacyName;

  /// What the customer was charged to have it brought. Zero when collecting.
  final double deliveryFee;
}