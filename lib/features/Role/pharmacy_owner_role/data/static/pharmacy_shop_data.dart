import '../../../../../core/constants/app_assets.dart';
import '../../domain/entities/pharmacy_shop.dart';

/// Sample data behind the pharmacy owner's section.
///
/// Static by design — this role is UI-first, so there is no repository or API
/// here; these shapes are what an endpoint will fill in.
class PharmacyShopData {
  PharmacyShopData._();

  static const Shop shop = Shop(
    name: 'Aid Plus+',
    ownerName: 'Mohammod Jakuan',
    phone: '+880 189* ****',
    location: 'Los Angels, USA',
    availableBalance: 160,
    email: 'alex@gmail.com',
    country: 'Cameron',
    address: 'Limasol , cyprus',
  );

  // ─── Dashboard ───────────────────────────────────────────────────────────

  static const String newOrders = '2';
  static const String newPrescriptions = '2';
  static const String todaysEarnings = r'$120';
  static const String lowStockItems = '4';

  static const List<StockAlert> stockAlerts = [
    StockAlert(medicineName: 'Amoxicillin 500mg', remaining: 3),
    StockAlert(medicineName: 'Metformin 500mg', remaining: 0),
    StockAlert(medicineName: 'Atorvastatin 20mg', remaining: 4),
  ];

  // ─── Orders ──────────────────────────────────────────────────────────────

  static const List<OrderLine> _lines = [
    OrderLine(name: 'Amoxicillin 500mg', quantity: 2, unitPrice: 16),
    OrderLine(name: 'Paracetamol 650mg', quantity: 3, unitPrice: 7.5),
    OrderLine(name: 'Vitamin D3 1000IU', quantity: 1, unitPrice: 12),
  ];

  /// Three orders in each state.
  ///
  /// The design's list shows one row per state at once, which is a showcase
  /// of the pills rather than a filtered list — the chips above it are a
  /// filter, so the book carries enough rows for every chip to land on a real
  /// list instead of a single line.
  static List<ShopOrder> orders() => [
    for (final status in ShopOrderStatus.values)
      for (var index = 0; index < 3; index++)
        ShopOrder(
          id: 'o-${status.name}-$index',
          code: 'ORD-2841',
          customerName: 'Sarah Johnson',
          initials: 'SJ',
          phone: '+1 555-0142',
          address: '142 Maple Street, Boston MA 02101',
          placedAtLabel: '10:32 AM',
          status: status,
          lines: _lines,
          prescriptionFile: 'Prescription.jpg',
        ),
  ];

  /// The dashboard lists the newest six rather than the whole book.
  static List<ShopOrder> recentOrders() => [
    for (var index = 0; index < 6; index++)
      ShopOrder(
        id: 'recent-$index',
        code: 'ORD-2841',
        customerName: 'Sarah Johnson',
        initials: 'SJ',
        phone: '+1 555-0142',
        address: '142 Maple Street, Boston MA 02101',
        placedAtLabel: '10:32 AM',
        status: ShopOrderStatus.fresh,
        lines: _lines,
        prescriptionFile: 'Prescription.jpg',
      ),
  ];

  // ─── Medicines ───────────────────────────────────────────────────────────

  static const List<ShopMedicine> medicines = [
    ShopMedicine(
      id: 'm-1',
      name: 'Paracetamol 500mg',
      category: 'Pain Relief',
      expiryLabel: '2028-03',
      stock: 128,
      price: 2.5,
      isListed: true,
      imageAsset: AppAssets.medicine,
    ),
    ShopMedicine(
      id: 'm-2',
      name: 'Ibuprofen 400mg',
      category: 'Anti-inflammatory',
      expiryLabel: '2029-06',
      stock: 75,
      price: 3,
      isListed: true,
      imageAsset: AppAssets.medicine,
    ),
    ShopMedicine(
      id: 'm-3',
      name: 'Aspirin 100mg',
      category: 'Blood Thinner',
      expiryLabel: '2027-12',
      stock: 200,
      price: 1.8,
      isListed: true,
      imageAsset: AppAssets.medicine,
    ),
    ShopMedicine(
      id: 'm-4',
      name: 'Amoxicillin 500mg',
      category: 'Antibiotic',
      expiryLabel: '2025-09',
      stock: 50,
      price: 4.2,
      isListed: true,
      imageAsset: AppAssets.medicine,
    ),
    ShopMedicine(
      id: 'm-5',
      name: 'Lisinopril 10mg',
      category: 'Blood Pressure',
      expiryLabel: '2026-11',
      stock: 90,
      price: 5,
      isListed: true,
      imageAsset: AppAssets.medicine,
    ),
    ShopMedicine(
      id: 'm-6',
      name: 'Cetirizine 10mg',
      category: 'Allergy Relief',
      expiryLabel: '2028-01',
      stock: 120,
      price: 3.5,
      isListed: true,
      imageAsset: AppAssets.medicine,
    ),
  ];

  static const List<String> categories = [
    'Pain Relief',
    'Anti-inflammatory',
    'Blood Thinner',
    'Antibiotic',
    'Blood Pressure',
    'Allergy Relief',
    'Vitamins',
  ];

  static const List<String> countries = [
    'Cameron',
    'Nigeria',
    'Kenya',
    'Ghana',
    'South Africa',
  ];

  // ─── Notifications ───────────────────────────────────────────────────────

  static const List<ShopNotification> notifications = [
    ShopNotification(
      title: 'New Order',
      body: 'Bill of Lading has been uploaded for OC-2026-4587',
      reference: 'OC-2026-4587',
      ageLabel: '1 day ago',
    ),
    ShopNotification(
      title: 'New Prescription Order',
      body: 'Bill of Lading has been uploaded for OC-2026-4587',
      reference: 'OC-2026-4587',
      ageLabel: '1 day ago',
    ),
    ShopNotification(
      title: 'Document Added',
      body: 'Bill of Lading has been uploaded for OC-2026-4587',
      reference: 'OC-2026-4587',
      ageLabel: '1 day ago',
    ),
    ShopNotification(
      title: 'Document Added',
      body: 'Bill of Lading has been uploaded for OC-2026-4587',
      reference: 'OC-2026-4587',
      ageLabel: '1 day ago',
    ),
  ];
}
