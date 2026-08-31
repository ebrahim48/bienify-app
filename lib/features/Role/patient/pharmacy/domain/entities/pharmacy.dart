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
    this.path = const [],
    this.distanceMeters,
    this.etaSeconds,
  });

  final String status;
  final MapPoint? courier;
  final MapPoint? pickup;
  final MapPoint? dropoff;

  /// When the courier last reported. A position from an hour ago is not a
  /// live one, and the sheet says so.
  final DateTime? reportedAt;

  /// The road itself, decoded from the server's polyline.
  ///
  /// Empty when nothing could route the journey — no key configured, no
  /// coordinates, or the provider was down. The map then joins the pins with a
  /// straight line, which is what it always drew: a line that is honestly a
  /// guess rather than a road nobody checked.
  final List<MapPoint> path;

  /// Along the road, from the courier to wherever they are heading next.
  /// Null when nothing measured it — never a zero standing in for unknown.
  final int? distanceMeters;

  /// Driving time to that same point, in seconds.
  final int? etaSeconds;

  bool get hasAnyPoint => courier != null || pickup != null || dropoff != null;

  /// Whether the road came back, as opposed to two pins and a straight line.
  bool get hasRoad => path.length > 1;

  /// Moves the courier without disturbing anything else.
  ///
  /// Every field is carried through explicitly, which is the whole point: a
  /// pushed position arrives several times a minute, and both tracking screens
  /// rebuilt this object by hand to apply one. Each omitted field reverted to
  /// its default on every ping — so the road and the arrival time, which the
  /// socket payload does not carry, were wiped the moment the courier moved.
  /// The map drew a route on open and lost it a few seconds later.
  DeliveryRoute movedTo(
    MapPoint courier, {
    String? status,
    DateTime? reportedAt,
  }) => DeliveryRoute(
    status: status ?? this.status,
    courier: courier,
    pickup: pickup,
    dropoff: dropoff,
    reportedAt: reportedAt ?? DateTime.now(),
    // Kept as it was. The road is re-routed by the server as the courier moves
    // away from where it was calculated, and arrives on the next read; until
    // then the last known road is a better answer than none.
    path: path,
    distanceMeters: distanceMeters,
    etaSeconds: etaSeconds,
  );

  /// Moves the parcel to a new state without claiming the courier reported.
  ///
  /// Separate from [movedTo] because that one takes a position and stamps
  /// `reportedAt` with now. A courier marking a parcel collected is not a
  /// position report — they may not have sent one at all yet — and reusing
  /// `movedTo` here would restart the "last seen" clock on a courier who has
  /// not moved, which is precisely the invented freshness the tracking sheet
  /// must not show.
  DeliveryRoute withStatus(String status) => DeliveryRoute(
    status: status,
    courier: courier,
    pickup: pickup,
    dropoff: dropoff,
    reportedAt: reportedAt,
    path: path,
    distanceMeters: distanceMeters,
    etaSeconds: etaSeconds,
  );

  /// `1.2 km`, or `450 m` under a kilometre. Null when unmeasured, so a caller
  /// omits the chip rather than printing `0.0 km`.
  String? get distanceLabel {
    final metres = distanceMeters;
    if (metres == null) return null;
    return metres < 1000
        ? '$metres m'
        : '${(metres / 1000).toStringAsFixed(1)} km';
  }

  /// `18 min`, or `1 h 05 min` past the hour. Rounded up: a courier eight
  /// seconds away is not "0 min".
  String? get etaLabel {
    final seconds = etaSeconds;
    if (seconds == null) return null;
    final minutes = (seconds / 60).ceil();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    return '$hours h ${(minutes % 60).toString().padLeft(2, '0')} min';
  }
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
