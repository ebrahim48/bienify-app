import '../entities/pharmacy_shop.dart';

/// Everything the shop owner's screens read and write.
///
/// One repository for the whole role, as with the practitioner: the dashboard,
/// the order book, the shelf and the profile are four views of the same
/// pharmacy.
abstract class PharmacyShopRepository {
  /// The shop itself — masthead, balance, and the details behind the profile.
  Future<Shop> shop();

  /// Medicines running low or out, for the dashboard's alert panel.
  Future<List<StockAlert>> stockAlerts();

  /// The order book, newest first.
  Future<List<ShopOrder>> orders();

  /// Moves an order to [status]. [reason] is only read when declining.
  Future<void> setOrderStatus(
    String orderId,
    ShopOrderStatus status, {
    String? reason,
  });

  /// Everything on the shelf, listed or not.
  Future<List<ShopMedicine>> medicines();

  /// Adds a medicine and returns it as the server stored it.
  ///
  /// [imageKey] is what [uploadMedicineImage] returned.
  Future<ShopMedicine> addMedicine({
    required String name,
    required double price,
    required int stock,
    required bool isListed,
    String category,
    DateTime? expiresOn,
    String? imageKey,
  });

  /// Writes [medicine] back whole, and returns it as the server stored it —
  /// not as sent, so a field the server ignores does not show as saved.
  ///
  /// Not a patch, despite the verb: the server validates the update against
  /// the same schema it validates a creation with, so a body carrying only the
  /// changed field is rejected for the fields it left out.
  Future<ShopMedicine> updateMedicine(
    ShopMedicine medicine, {
    String? imageKey,
  });

  /// Uploads a product photo and returns the key to save it under.
  Future<String> uploadMedicineImage({
    required String path,
    required String mimeType,
  });

  /// The server has no delete for a medicine — a product with orders against
  /// it cannot vanish — so removing one delists it.
  Future<void> delistMedicine(ShopMedicine medicine);

  Future<void> saveShopDetails({
    required String name,
    required String address,
    required String city,
    required String licenceNumber,
  });

  Future<List<ShopNotification>> notifications();

  /// The dashboard figures — `GET /pharmacies/me/stats`.
  Future<ShopStats> stats();
}
