import '../entities/pharmacy.dart';

/// Browsing medicines, choosing a pharmacy and placing an order.
abstract class PharmacyRepository {
  /// The catalogue, optionally narrowed by [query] or to one [pharmacyId].
  Future<List<Medicine>> searchMedicines({String query, String? pharmacyId});

  /// Pharmacies that can fulfil an order, optionally narrowed to a [city].
  ///
  /// The server has filtered on city since the endpoint was written
  /// (`pharmacy.service.ts:65`); the app simply never sent one, so every
  /// patient saw the same national list under the heading "near you".
  Future<List<PharmacyStore>> stores({String query, String city});

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
    /// Where the parcel is going, when the patient pinned it.
    ///
    /// The server geocodes the address line when these are absent, which is a
    /// guess and returns nothing at all without a Maps key — so an unpinned
    /// order usually leaves the courier's map with no destination.
    double? deliveryLat,
    double? deliveryLng,
  });

  /// Pays for a placed order out of the patient's wallet.
  ///
  /// Until this is called the order sits in `pending_payment`, where the
  /// pharmacy is shown it as new but the server refuses to let them accept
  /// it — so an unpaid order is a dead end on both sides.
  Future<void> payOrder(String orderId);

  /// The patient's orders, newest first.
  Future<List<PharmacyOrder>> orders();

  /// Cancels an order the pharmacy has not dispatched yet —
  /// `POST /medicine-orders/:id/cancel`.
  ///
  /// The server refuses anything past `preparing`: once a rider is carrying
  /// the parcel, cancelling is a delivery problem rather than an order one.
  /// See [PharmacyOrder.isCancellable] for the statuses that qualify.
  Future<void> cancelOrder(String orderId);

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

  /// Rates the shop that filled an order — `POST /reviews` with
  /// `subjectKind: 'pharmacy'`.
  ///
  /// The order names the subject; the server derives the pharmacy from it, so
  /// a patient cannot rate a shop they never bought from. It also refuses
  /// anything that is not `delivered` yet.
  Future<void> reviewPharmacy({required String orderId, required int rating});

  /// Rates the courier who carried a delivery — `POST /reviews` with
  /// `subjectKind: 'rider'`.
  ///
  /// Keyed by the **delivery**, not the order: `review.service.ts:55` resolves
  /// the rider from the delivery, and an order id there is simply not found.
  Future<void> reviewRider({required String deliveryId, required int rating});
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

  /// Whether the patient can still call it off.
  ///
  /// Mirrors `CUSTOMER_CANCELLABLE` (`pharmacy.model.ts:29`). Kept in the
  /// entity rather than the screen so the tracking view and any future list
  /// cannot disagree about when the button appears — and so a button never
  /// appears for an order the server would refuse to cancel.
  bool get isCancellable => const {
    'pending_payment',
    'placed',
    'accepted',
    'preparing',
  }.contains(status);
  final DateTime placedAt;
  final String deliveryAddress;

  /// Who is filling it. The timeline used to name one demo pharmacy on every
  /// patient's order.
  final String pharmacyName;

  /// What the customer was charged to have it brought. Zero when collecting.
  final double deliveryFee;
}