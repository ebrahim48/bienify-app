/// Shapes used across the Pharmacy journey.
///
/// The types the pharmacy screens are built on. Filled from the API by
/// `PharmacyRepository` and the mappers in `core/network/mappers.dart`.
library;

export '../../../../../../core/models/delivery_address.dart';

/// A product in the catalogue or on a prescription.
class Medicine {
  const Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.price,
    this.oldPrice,
    this.packSize,
    this.discountPercent = 0,
    this.isAvailable = true,
    this.pharmacyId = '',
  });

  final String id;
  final String name;

  /// Which dispensary stocks it. An order names one pharmacy, so this is what
  /// says where a basket built from the catalogue should be sent.
  final String pharmacyId;

  /// e.g. `25mg`.
  final String dosage;

  final double price;

  /// Pre-discount price, struck through on the catalogue card.
  final double? oldPrice;

  /// e.g. `21 capsules`; shown next to the dosage on prescription rows.
  final String? packSize;

  final int discountPercent;

  /// False renders the row greyed with a "Not Available" tag.
  final bool isAvailable;

  String get priceLabel => '\$${price.toStringAsFixed(2)}';

  /// The catalogue shows whole dollars, e.g. `$30`.
  String get shortPriceLabel => '\$${price.toStringAsFixed(0)}';

  String? get oldPriceLabel =>
      oldPrice == null ? null : '\$${oldPrice!.toStringAsFixed(0)}';

  /// `25mg · 21 capsules`, or just the dosage when there is no pack size.
  String get detailLabel => packSize == null ? dosage : '$dosage · $packSize';
}

/// A medicine plus how many of it are in the basket.
class CartLine {
  const CartLine({required this.medicine, this.quantity = 1});

  final Medicine medicine;
  final int quantity;

  double get total => medicine.price * quantity;

  CartLine copyWith({int? quantity}) =>
      CartLine(medicine: medicine, quantity: quantity ?? this.quantity);
}

/// A dispensary that can fulfil a prescription.
class PharmacyStore {
  const PharmacyStore({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceLabel,
    required this.rating,
    required this.reviewCount,
    required this.etaLabel,
    required this.price,
    required this.availableCount,
    required this.totalCount,
    this.logoAsset,
  });

  final String id;
  final String name;
  final String address;

  /// e.g. `0.8 km`.
  final String distanceLabel;

  final double rating;
  final int reviewCount;

  /// e.g. `25—35 min`.
  final String etaLabel;

  final double price;

  /// How many of the prescription's medicines this store stocks.
  final int availableCount;
  final int totalCount;

  final String? logoAsset;

  String get priceLabel => '\$${price.toStringAsFixed(0)}';

  String get ratingLabel => rating.toStringAsFixed(1);

  /// Drives the availability bar, 0–1.
  double get availabilityFraction =>
      totalCount == 0 ? 0 : availableCount / totalCount;

  /// First letter, used when there is no logo.
  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();
}

/// An uploaded prescription and what was read off it.
class Prescription {
  const Prescription({
    required this.doctorName,
    required this.medicineCount,
    required this.uploadedLabel,
  });

  final String doctorName;
  final int medicineCount;

  /// e.g. `Just uploaded`.
  final String uploadedLabel;
}

/// Where an order is delivered.
/// The stages an order moves through, in order.
enum OrderStage {
  placed,
  pharmacyConfirmed,
  beingPrepared,
  readyForPickup,
  courierAssigned,
  outForDelivery,
  delivered,
}

/// One row of the order-progress timeline.
class OrderStep {
  const OrderStep({
    required this.stage,
    required this.title,
    required this.subtitle,
  });

  final OrderStage stage;
  final String title;
  final String subtitle;
}

/// One point on the tracking map.
class MapPoint {
  const MapPoint({required this.lat, required this.lng, this.label = ''});

  final double lat;
  final double lng;

  /// The pharmacy's name, or the delivery address. Empty for the courier.
  final String label;
}

/// Where the courier is, where they set off from, and where they are going.
///
/// Every field is optional and independently so. A pharmacy that has not
/// recorded its coordinates has no pickup pin; an address the patient typed
/// without granting location has no destination; and a courier who has not
/// reported yet has no position. A missing pin is honest — the four constants
/// this replaces put every order on the same route.
class DeliveryRoute {
  const DeliveryRoute({
    required this.status,
    this.courier,
    this.pickup,
    this.dropoff,
    this.reportedAt,
  });

  final String status;
  final MapPoint? courier;
  final MapPoint? pickup;
  final MapPoint? dropoff;

  /// When the courier last reported. A position from an hour ago is not a
  /// live one, and the sheet says so.
  final DateTime? reportedAt;

  bool get hasAnyPoint => courier != null || pickup != null || dropoff != null;
}

/// The courier carrying an order, as the tracking sheet shows them.
class Courier {
  const Courier({
    required this.id,
    required this.name,
    this.photoUrl = '',
    this.rating = 0,
    this.reviewCount = 0,
    this.vehicleType = '',
    this.city = '',
  });

  final String id;
  final String name;
  final String photoUrl;

  /// Zero means nobody has rated them yet, which the sheet says rather than
  /// printing a score. It used to show 4.9 from a constant for every courier.
  final double rating;
  final int reviewCount;

  final String vehicleType;
  final String city;

  bool get hasRating => reviewCount > 0;
}
