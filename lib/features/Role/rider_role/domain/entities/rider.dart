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
  });

  final String name;

  /// `Los Angels, USA`.
  final String location;

  final double todaysEarnings;
  final int deliveriesToday;
  final double rating;

  /// Whether the courier is accepting work.
  final bool isOnline;

  final String email;
  final String country;
  final String city;
  final String address;

  /// `motorbike` — what the courier delivers on, as the server stores it.
  final String vehicleType;

  final String licenceNumber;

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
    isOnline: isOnline ?? this.isOnline,
    email: email,
    country: country,
    city: city,
    address: address,
    vehicleType: vehicleType,
    licenceNumber: licenceNumber,
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
    required this.minutes,
    required this.distanceKm,
    required this.items,
    required this.tab,
  });

  final String id;

  /// `ORD-4821`.
  final String code;

  final double fee;

  /// `MedPlus Pharmacy`.
  final String pickupName;

  final String customerName;
  final String customerAddress;

  /// `12` — minutes to complete.
  final int minutes;

  final double distanceKm;

  /// `Insulin pens × 2, Syringes × 10`.
  final String items;

  final RequestTab tab;

  /// `+$4.50` — a fee is always a gain, so it carries its sign.
  String get feeLabel => '+\$${fee.toStringAsFixed(2)}';

  /// `1.2 km`.
  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km';

  /// `12 min`.
  String get minutesLabel => '$minutes min';

  DeliveryRequest copyWith({RequestTab? tab}) => DeliveryRequest(
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
class ActiveDelivery {
  const ActiveDelivery({
    required this.roadName,
    required this.arrivingAtLabel,
    required this.latestArrivalLabel,
    required this.stepsLeft,
    required this.minutesAway,
    required this.request,
    required this.note,
    required this.unreadMessages,
  });

  /// `Los Angels road`.
  final String roadName;

  /// `2:52 PM`.
  final String arrivingAtLabel;

  /// `3:15 PM`.
  final String latestArrivalLabel;

  final int stepsLeft;
  final int minutesAway;

  final DeliveryRequest request;

  /// What the customer asked for, shown when View Note is tapped.
  final String note;

  final int unreadMessages;
}

/// The receipt shown once a package changes hands.
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
