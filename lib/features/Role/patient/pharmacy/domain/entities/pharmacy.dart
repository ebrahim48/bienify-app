/// Shapes used across the Pharmacy journey.
///
/// **Names only, by design.** This feature is UI-first: no repository, use
/// case or data source, and nothing calls an API. The models exist so the
/// widgets have typed inputs and the swap to live data is a matter of
/// filling these in.
library;

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
  });

  final String id;
  final String name;

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
class DeliveryAddress {
  const DeliveryAddress({
    required this.line1,
    required this.line2,
    this.note,
    this.doorImageName,
  });

  final String line1;
  final String line2;

  /// Courier instructions.
  final String? note;

  /// File name of the door photo, when one has been attached.
  final String? doorImageName;
}

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
