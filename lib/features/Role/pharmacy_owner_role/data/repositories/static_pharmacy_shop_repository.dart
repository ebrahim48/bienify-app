import '../../domain/entities/pharmacy_shop.dart';
import '../../domain/repositories/pharmacy_shop_repository.dart';
import '../static/pharmacy_shop_data.dart';

/// The shop, served from the design's sample data.
///
/// Golden and widget tests assert on rendering, so they must not depend on a
/// backend being up or on what happens to be in its database. Writes are
/// accepted and dropped — the screens show their own confirmation.
class StaticPharmacyShopRepository implements PharmacyShopRepository {
  const StaticPharmacyShopRepository();

  @override
  Future<Shop> shop() async => PharmacyShopData.shop;

  @override
  Future<List<StockAlert>> stockAlerts() async =>
      List.of(PharmacyShopData.stockAlerts);

  @override
  Future<List<ShopOrder>> orders() async => PharmacyShopData.orders();

  @override
  Future<void> setOrderStatus(
    String orderId,
    ShopOrderStatus status, {
    String? reason,
  }) async {}

  @override
  Future<List<ShopMedicine>> medicines() async =>
      List.of(PharmacyShopData.medicines);

  @override
  Future<ShopMedicine> addMedicine({
    required String name,
    required double price,
    required int stock,
    required bool isListed,
    String category = '',
    DateTime? expiresOn,
    String? imageKey,
  }) async => ShopMedicine(
    id: 'medicine-${DateTime.now().microsecondsSinceEpoch}',
    name: name,
    category: category,
    expiresOn: expiresOn,
    stock: stock,
    price: price,
    isListed: isListed,
  );

  /// Echoes the row back, as the server's update will once it stores expiry.
  @override
  Future<ShopMedicine> updateMedicine(
    ShopMedicine medicine, {
    String? imageKey,
  }) async => medicine;

  /// There is no bucket behind the sample data, so there is no key to issue
  /// that would resolve to a picture; the form keeps its local preview.
  @override
  Future<String> uploadMedicineImage({
    required String path,
    required String mimeType,
  }) async => 'sample/medicine-image';

  @override
  Future<void> delistMedicine(ShopMedicine medicine) async {}

  @override
  Future<void> saveShopDetails({
    required String name,
    required String address,
    required String city,
    required String licenceNumber,
  }) async {}

  @override
  Future<List<ShopNotification>> notifications() async =>
      List.of(PharmacyShopData.notifications);

  @override
  Future<ShopStats> stats() async => const ShopStats(
    newOrders: 12,
    preparing: 3,
    newPrescriptions: 5,
    todaysEarnings: 284.50,
    lowStockItems: 4,
    outOfStockItems: 1,
  );
}
