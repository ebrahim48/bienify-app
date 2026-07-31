import '../../domain/entities/pharmacy.dart';

/// Content behind the Pharmacy screens.
///
/// Static because the feature is UI-only for now; a repository will return
/// these same shapes.
class PharmacyMockData {
  PharmacyMockData._();

  // ─── Catalogue ───────────────────────────────────────────────────────────

  /// Search suggestion chips.
  static const List<String> searchChips = [
    'ex 50',
    'Napa 50',
    'Cosec 50',
    'Biltin 50',
    'emojil',
    'fiver 50',
  ];

  /// The three names the designs cycle through across a six-tile grid.
  static const List<String> _catalogueNames = [
    'Cecon',
    'Algecal DX',
    'Calcium-D',
  ];

  static List<Medicine> catalogue(String prefix) => [
    for (var index = 0; index < 6; index++)
      Medicine(
        id: '$prefix-$index',
        name: _catalogueNames[index % _catalogueNames.length],
        dosage: '25mg',
        price: 30,
        oldPrice: 50,
        discountPercent: 10,
      ),
  ];

  static List<Medicine> get commonMedicines => catalogue('common');

  static List<Medicine> get dermatologyMedicines => catalogue('derma');

  /// "Stores Near You" — logo-less, so the UI falls back to initials.
  static const List<PharmacyStore> nearbyStores = [
    PharmacyStore(
      id: 'store-1',
      name: 'Medica',
      address: '14 Health Street, Downtown',
      distanceLabel: '0.8 km',
      rating: 4.8,
      reviewCount: 312,
      etaLabel: '25—35 min',
      price: 350,
      availableCount: 6,
      totalCount: 6,
    ),
    PharmacyStore(
      id: 'store-2',
      name: 'Green Life',
      address: '22 Park Avenue',
      distanceLabel: '1.1 km',
      rating: 4.6,
      reviewCount: 180,
      etaLabel: '30—40 min',
      price: 340,
      availableCount: 5,
      totalCount: 6,
    ),
    PharmacyStore(
      id: 'store-3',
      name: 'Alsheba pharma',
      address: '5 River Road',
      distanceLabel: '1.4 km',
      rating: 4.7,
      reviewCount: 210,
      etaLabel: '30—45 min',
      price: 360,
      availableCount: 4,
      totalCount: 6,
    ),
    PharmacyStore(
      id: 'store-4',
      name: 'Pharma Mart',
      address: '9 Market Lane',
      distanceLabel: '1.8 km',
      rating: 4.5,
      reviewCount: 150,
      etaLabel: '35—45 min',
      price: 355,
      availableCount: 4,
      totalCount: 6,
    ),
    PharmacyStore(
      id: 'store-5',
      name: 'Medico Plus',
      address: '31 Hill Street',
      distanceLabel: '2.2 km',
      rating: 4.4,
      reviewCount: 120,
      etaLabel: '40—50 min',
      price: 345,
      availableCount: 3,
      totalCount: 6,
    ),
  ];

  // ─── Prescription flow ───────────────────────────────────────────────────

  static const Prescription prescription = Prescription(
    doctorName: 'Dr. Sarah Mitchell',
    medicineCount: 6,
    uploadedLabel: 'Just uploaded',
  );

  static const String searchArea = '123 Main Street, New York';

  /// The three candidates on "Best Matches", differing only in how much of
  /// the prescription they stock.
  static const List<PharmacyStore> matches = [
    PharmacyStore(
      id: 'match-1',
      name: 'MediQuick Pharmacy',
      address: '14 Health Street, Downtown',
      distanceLabel: '0.8 km',
      rating: 4.8,
      reviewCount: 312,
      etaLabel: '25—35 min',
      price: 350,
      availableCount: 6,
      totalCount: 6,
    ),
    PharmacyStore(
      id: 'match-2',
      name: 'HealthPlus Pharmacy',
      address: '8 Garden Road',
      distanceLabel: '0.8 km',
      rating: 4.8,
      reviewCount: 312,
      etaLabel: '25—35 min',
      price: 350,
      availableCount: 5,
      totalCount: 6,
    ),
    PharmacyStore(
      id: 'match-3',
      name: 'CityCare Pharmacy',
      address: '2 Union Square',
      distanceLabel: '0.8 km',
      rating: 4.8,
      reviewCount: 312,
      etaLabel: '25—35 min',
      price: 350,
      availableCount: 4,
      totalCount: 6,
    ),
  ];

  /// The prescription's six lines. The last is out of stock at stores that
  /// cannot fill the whole script.
  static const List<Medicine> prescribed = [
    Medicine(
      id: 'rx-1',
      name: 'Amoxicillin',
      dosage: '500mg',
      packSize: '21 capsules',
      price: 12.50,
    ),
    Medicine(
      id: 'rx-2',
      name: 'Metformin',
      dosage: '850mg',
      packSize: '60 tablets',
      price: 8.90,
    ),
    Medicine(
      id: 'rx-3',
      name: 'Lisinopril',
      dosage: '10mg',
      packSize: '30 tablets',
      price: 15.20,
    ),
    Medicine(
      id: 'rx-4',
      name: 'Atorvastatin',
      dosage: '20mg',
      packSize: '30 tablets',
      price: 22.00,
    ),
    Medicine(
      id: 'rx-5',
      name: 'Omeprazole',
      dosage: '20mg',
      packSize: '28 capsules',
      price: 9.80,
    ),
    Medicine(
      id: 'rx-6',
      name: 'Paracetamol',
      dosage: '500mg',
      packSize: '16 tablets',
      price: 3.50,
    ),
  ];

  // ─── Order ───────────────────────────────────────────────────────────────

  static const double deliveryFee = 2.99;
  static const double walletBalance = 45;
  static const String orderId = '#RX8841';
  static const String deliveryWindow = 'Today, 3:45 PM — 3:55 PM';
  static const String deliveryEta = '~25 min';

  static const DeliveryAddress address = DeliveryAddress(
    line1: '123 Main Street, Apt 4B',
    line2: 'New York, NY 10001',
  );

  static const List<OrderStep> orderSteps = [
    OrderStep(
      stage: OrderStage.placed,
      title: 'Order Placed',
      subtitle: 'Confirmed $orderId',
    ),
    OrderStep(
      stage: OrderStage.pharmacyConfirmed,
      title: 'Pharmacy Confirmed',
      subtitle: 'MediQuick accepted',
    ),
    OrderStep(
      stage: OrderStage.beingPrepared,
      title: 'Being Prepared',
      subtitle: 'Pharmacist is packing your order',
    ),
    OrderStep(
      stage: OrderStage.readyForPickup,
      title: 'Ready for Pickup',
      subtitle: 'Estimated in ~20 min',
    ),
    OrderStep(
      stage: OrderStage.courierAssigned,
      title: 'Courier Assigned',
      subtitle: 'Estimated in ~20 min',
    ),
    OrderStep(
      stage: OrderStage.outForDelivery,
      title: 'Out for Delivery',
      subtitle: 'Estimated in ~20 min',
    ),
    OrderStep(
      stage: OrderStage.delivered,
      title: 'Delivered',
      subtitle: 'To your door',
    ),
  ];

  // ─── Live tracking ───────────────────────────────────────────────────────

  static const String riderName = 'Rider Arif';
  static const String riderCountry = 'usa';
  static const double riderRating = 4.9;
  static const int riderReviews = 1234;
  static const String routeTitle = 'Los Angels road';
  static const String arrivingAt = 'Now Arriving 2:52 PM';
  static const String latestArrival = 'Latest arrival time 3:15 PM';
  static const String minutesAway = '15 min away';
  static const String pickupFrom = 'MedPlus Pharmacy';
  static const String deliverTo = 'Sarah Johnson';
  static const String deliverToAddress = '14 Maple Street, Apt 3B';

  /// Courier and destination, for the tracking map.
  static const double courierLatitude = 37.4419;
  static const double courierLongitude = -122.1430;
  static const double destinationLatitude = 37.4275;
  static const double destinationLongitude = -122.1697;
}
