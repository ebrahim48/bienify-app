/// Shapes behind the courier's section.
///
/// Served by `RiderRepository` — the API implementation reads them off
/// `riders/me`, `deliveries` and `wallet`; the static one keeps the design's
/// sample data for tests and for walking the app without a server.
library;

/// Which tab of the rider shell is showing.
enum RiderTab { home, orders, earnings, profile }

/// What the courier delivers on.
enum VehicleType { bicycle, bike, car }

/// Which chip is active above the request list.
enum RequestTab { fresh, accepted, cancelled }

/// The signed-in courier, as the dashboard masthead shows them.
class Rider {
  const Rider({
    required this.name,
    required this.location,
    required this.todaysEarnings,
    required this.deliveriesToday,
    required this.rating,
    required this.isOnline,
    required this.email,
    required this.country,
    required this.city,
    required this.address,
    this.vehicleType = 'motorbike',
    this.licenceNumber = '',
    this.photoUrl,
    this.phone = '',
    this.zones = const [],
    this.shareLiveLocation = true,
    this.reviewCount = 0,
    this.deliveriesCompleted = 0,
  });

  final String name;

  /// `Los Angels, USA`.
  final String location;

  final double todaysEarnings;
  final int deliveriesToday;
  final double rating;

  /// How many customers have rated them, and how much work they have finished.
  /// A 5.0 from one delivery reads very differently from a 4.6 from forty.
  final int reviewCount;
  final int deliveriesCompleted;

  /// Whether the courier is accepting work.
  final bool isOnline;

  final String email;
  final String country;
  final String city;
  final String address;

  /// `motorbike` — what the courier delivers on, as the server stores it.
  final String vehicleType;

  final String licenceNumber;

  /// The courier's own picture, when the server has one.
  final String? photoUrl;

  /// The areas they cover. Their own choice — empty until they make it.
  final List<String> zones;

  /// Whether they share position while carrying a parcel. On by default; the
  /// customer's tracking map is what depends on it.
  final bool shareLiveLocation;

  /// `+15550000004` — what the Profile tab prints under the name.
  final String phone;

  /// `$21.75`.
  String get earningsLabel => '\$${todaysEarnings.toStringAsFixed(2)}';

  /// `4.9`, or a dash when nobody has rated the courier yet.
  String get ratingLabel => rating <= 0 ? '—' : rating.toStringAsFixed(1);

  Rider copyWith({bool? isOnline}) => Rider(
    name: name,
    location: location,
    todaysEarnings: todaysEarnings,
    deliveriesToday: deliveriesToday,
    rating: rating,
    // Carried through explicitly. Every field this misses silently reverts to
    // its default — going online would have reset the courier's own rating,
    // review count and completed deliveries to zero on the masthead.
    reviewCount: reviewCount,
    deliveriesCompleted: deliveriesCompleted,
    zones: zones,
    shareLiveLocation: shareLiveLocation,
    isOnline: isOnline ?? this.isOnline,
    email: email,
    country: country,
    city: city,
    address: address,
    vehicleType: vehicleType,
    licenceNumber: licenceNumber,
    photoUrl: photoUrl,
    phone: phone,
  );
}

/// One step of the How It Works guide.
class GuideStep {
  const GuideStep({
    required this.title,
    required this.body,
    required this.note,
  });

  /// Carries its own emoji, as the design draws it.
  final String title;
  final String body;

  /// The paler third line.
  final String note;
}

/// A delivery job, from the request card through to its receipt.
class DeliveryRequest {
  const DeliveryRequest({
    required this.id,
    required this.code,
    required this.fee,
    required this.pickupName,
    required this.customerName,
    required this.customerAddress,
    this.customerId = '',
    required this.minutes,
    required this.distanceKm,
    required this.items,
    required this.tab,
    this.status = '',
  });

  final String id;

  /// `ORD-4821`.
  final String code;

  final double fee;

  /// `MedPlus Pharmacy`.
  final String pickupName;

  final String customerName;
  final String customerAddress;

  /// The customer's account, which the courier's thread needs for presence.
  /// Empty on a job board row where the delivery is not yet theirs.
  final String customerId;

  /// `12` — minutes to complete.
  final int minutes;

  final double distanceKm;

  /// `Insulin pens × 2, Syringes × 10`.
  final String items;

  final RequestTab tab;

  /// Where the parcel is, in the server's own vocabulary: `unassigned`,
  /// `assigned`, `picked_up`, `in_transit`, `delivered` or `failed`.
  ///
  /// The three chips above the list collapse these, but moving a parcel along
  /// needs the exact one — the server only accepts the next state in sequence.
  final String status;

  /// Whether the parcel has already changed hands.
  ///
  /// A finished job sits under Accepted with the work the courier took, but it
  /// is not work they can still do: it offers no tracking and cannot be
  /// delivered again.
  bool get isDelivered => status == 'delivered';

  /// `+$4.50` — a fee is always a gain, so it carries its sign.
  String get feeLabel => '+\$${fee.toStringAsFixed(2)}';

  /// `1.2 km`.
  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km';

  /// `12 min`.
  String get minutesLabel => '$minutes min';

  DeliveryRequest copyWith({RequestTab? tab, String? status}) =>
      DeliveryRequest(
    id: id,
    code: code,
    fee: fee,
    pickupName: pickupName,
    customerName: customerName,
    customerAddress: customerAddress,
    minutes: minutes,
    distanceKm: distanceKm,
    items: items,
    tab: tab ?? this.tab,
    status: status ?? this.status,
  );
}

/// A finished delivery, on the dashboard and in the earnings history.
class DeliveryRecord {
  const DeliveryRecord({
    required this.customerName,
    required this.initials,
    required this.whenLabel,
    required this.fee,
    required this.orderCode,
  });

  final String customerName;

  /// `TC`, on the blue disc.
  final String initials;

  /// `Today, 10:42 AM`.
  final String whenLabel;

  final double fee;

  /// `ORD-4819` — printed under the fee in the history, omitted on the
  /// dashboard.
  final String orderCode;

  String get feeLabel => '+\$${fee.toStringAsFixed(2)}';
}

/// What the courier has made, and when the next payout lands.
class RiderEarnings {
  const RiderEarnings({
    required this.today,
    required this.todayCount,
    required this.thisWeek,
    required this.weekCount,
    required this.payoutDay,
    required this.payoutMinimum,
    required this.history,
  });

  final double today;
  final int todayCount;
  final double thisWeek;
  final int weekCount;

  /// `Friday`.
  final String payoutDay;

  /// The threshold a payout has to clear.
  final double payoutMinimum;

  final List<DeliveryRecord> history;

  String get todayLabel => '\$${today.toStringAsFixed(2)}';

  String get weekLabel => '\$${thisWeek.toStringAsFixed(2)}';

  String get minimumLabel => '\$${payoutMinimum.toStringAsFixed(0)}';

  /// How full the payout bar is, capped so an unusually good week does not
  /// overrun the track.
  double get payoutProgress =>
      payoutMinimum == 0 ? 1 : (thisWeek / payoutMinimum).clamp(0.0, 1.0);

  bool get hasClearedMinimum => thisWeek >= payoutMinimum;
}

/// The live job the courier is on.
/// The job a courier is currently on, as the tracking screen shows it.
///
/// It used to wrap a real job in a set of invented navigation figures: a road
/// name ("Los Angels road"), an arrival time, a latest-arrival time, a
/// minutes-away chip and a three-of-four step count — none of which anything
/// computed. There is no routing service behind this screen: no road is
/// resolved, no distance measured and no arrival estimated, so the courier was
/// being told a journey nobody had planned.
///
/// What is real is where they are going, how far through the job they are, and
/// the job itself.
class ActiveDelivery {
  const ActiveDelivery({
    required this.request,
    required this.status,
    this.unreadMessages = 0,
  });

  final DeliveryRequest request;

  /// The server's delivery status, which is what the step bar reads.
  final String status;

  final int unreadMessages;

  /// Where the parcel is going. The heading on the tracking sheet.
  String get destination => request.customerAddress;

  /// How many of the four steps are done: claimed, collected, on the road,
  /// handed over. Derived rather than declared, so it cannot disagree with the
  /// status the server holds.
  int get stepsDone => switch (status) {
    'assigned' => 1,
    'picked_up' => 2,
    'in_transit' => 3,
    'delivered' => 4,
    _ => 0,
  };

  int get stepsLeft => 4 - stepsDone;
}

class DeliveryReceipt {
  const DeliveryReceipt({
    required this.orderId,
    required this.customerName,
    required this.location,
    required this.timeLabel,
  });

  /// `#45892`.
  final String orderId;

  final String customerName;

  /// `Banani, Dhaka`.
  final String location;

  /// `4:32 PM`.
  final String timeLabel;
}
