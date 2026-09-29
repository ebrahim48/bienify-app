import 'dart:io';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/attachment_uploader.dart';
import '../../../../../core/network/mappers.dart';
import '../../domain/entities/pharmacy_shop.dart';
import '../../domain/repositories/pharmacy_shop_repository.dart';

/// The shop, served by the API.
class ApiPharmacyShopRepository implements PharmacyShopRepository {
  const ApiPharmacyShopRepository(this._api, this._uploader);

  final ApiClient _api;
  final AttachmentUploader _uploader;

  /// The server caps a page at 100, and none of these lists page in the
  /// design.
  static const int _pageSize = 100;

  // ─── Shop ────────────────────────────────────────────────────────────────

  @override
  Future<Shop> shop() async {
    final results = await Future.wait([
      _api.getMap(ApiConstants.usersMe),
      _api.getMap(ApiConstants.pharmaciesMe),
      _api.getMap(ApiConstants.wallet),
    ]);

    final user = results[0];
    final pharmacy = results[1];
    final wallet = results[2];

    final city = Api.str(pharmacy['city']);
    final address = Api.str(pharmacy['addressLine']);

    return Shop(
      name: Api.str(pharmacy['name'], 'Pharmacy'),
      ownerName: Api.nameOf(user, 'Owner'),
      phone: Api.str(pharmacy['phone'], Api.str(user['phone'])),
      // The masthead's second line is where the shop is, which is the city
      // rather than the street it stands on.
      location: city,
      availableBalance: Api.majorUnits(wallet['balanceMinor']),
      email: Api.str(user['email']),
      country: city,
      address: address,
      licenceNumber: Api.str(pharmacy['licenseNumber']),
      photoUrl: Api.avatarOf(user),
    );
  }

  @override
  Future<List<StockAlert>> stockAlerts() async {
    final data = await _api.getMap(ApiConstants.pharmaciesStockAlerts);

    // Two lists come back, and the panel shows one — out of stock first,
    // because an empty shelf is the more urgent of the two.
    return [
      for (final row in Api.rows(data['outOfStock']))
        StockAlert(
          medicineName: Api.str(row['name'], 'Medicine'),
          remaining: 0,
        ),
      for (final row in Api.rows(data['lowStock']))
        StockAlert(
          medicineName: Api.str(row['name'], 'Medicine'),
          remaining: Api.integer(row['stock']),
        ),
    ];
  }

  @override
  Future<void> saveShopDetails({
    required String name,
    required String address,
    required String city,
    required String licenceNumber,
  }) async {
    // `POST /pharmacies/me` upserts, so the same route creates the shop and
    // edits it.
    await _api.post(
      ApiConstants.postPharmaciesMe,
      body: {
        if (name.isNotEmpty) 'name': name,
        if (address.isNotEmpty) 'addressLine': address,
        if (city.isNotEmpty) 'city': city,
        if (licenceNumber.isNotEmpty) 'licenseNumber': licenceNumber,
      },
    );
  }

  // ─── Orders ──────────────────────────────────────────────────────────────

  @override
  Future<List<ShopOrder>> orders() async {
    // `/medicine-orders` is the *customer's* book — it filters on patientId,
    // so a shop asking for it gets an empty list with a 200. The shop's own
    // orders are under its own resource.
    final rows = await _api.getList(
      ApiConstants.pharmaciesMeOrders,
      query: {'limit': _pageSize},
    );
    return rows.map(shopOrderFrom).toList();
  }

  @override
  Future<void> setOrderStatus(
    String orderId,
    ShopOrderStatus status, {
    String? reason,
  }) async {
    await _api.patch(
      ApiConstants.updateMedicineOrdersStatus(orderId),
      body: {
        'status': shopOrderStatusTo(status),
        if (reason != null && reason.isNotEmpty) 'rejectionReason': reason,
      },
    );
  }

  // ─── Shelf ───────────────────────────────────────────────────────────────

  @override
  Future<List<ShopMedicine>> medicines() async {
    // Scoped to this shop: `/medicines` unfiltered is the whole marketplace,
    // which is the customer's catalogue and not the owner's shelf.
    final pharmacy = await _api.getMap(ApiConstants.pharmaciesMe);
    final rows = await _api.getList(
      ApiConstants.medicines,
      query: {'pharmacyId': Api.id(pharmacy), 'limit': _pageSize},
    );
    return rows.map(shopMedicineFrom).toList();
  }

  @override
  Future<ShopMedicine> addMedicine({
    required String name,
    required double price,
    required int stock,
    required bool isListed,
    String category = '',
    DateTime? expiresOn,
    String? imageKey,
  }) async {
    final data = await _api.postMap(
      ApiConstants.postPharmaciesMeMedicines,
      body: {
        'name': name,
        'priceMinor': (price * 100).round(),
        'stock': stock,
        'isActive': isListed,
        if (category.isNotEmpty) 'brand': category,
        if (expiresOn != null) 'expiryDate': medicineExpiryTo(expiresOn),
        'imageKey': ?imageKey,
      },
    );
    return shopMedicineFrom(data);
  }

  @override
  Future<ShopMedicine> updateMedicine(
    ShopMedicine medicine, {
    String? imageKey,
  }) async {
    final data = await _api.patch(
      ApiConstants.updatePharmaciesMeMedicines(medicine.id),
      body: {
        'name': medicine.name,
        'priceMinor': (medicine.price * 100).round(),
        'stock': medicine.stock,
        'isActive': medicine.isListed,
        if (medicine.category.isNotEmpty) 'brand': medicine.category,
        // Sent whole like the rest: a null clears a recorded expiry.
        'expiryDate': medicine.expiresOn == null
            ? null
            : medicineExpiryTo(medicine.expiresOn!),
        'imageKey': ?imageKey,
      },
    );
    // The stored row when the response carries it, so an expiry or photo the
    // server did not keep does not show as saved. What was sent otherwise.
    final stored = Api.map(data);
    return Api.id(stored).isEmpty ? medicine : shopMedicineFrom(stored);
  }

  @override
  Future<String> uploadMedicineImage({
    required String path,
    required String mimeType,
  }) async {
    final file = File(path);
    final issued = await _api.postMap(
      ApiConstants.postPharmaciesMeMedicinesImageUploadUrl,
      body: {'contentType': mimeType},
    );
    final url = '${issued['url'] ?? ''}';
    final key = '${issued['key'] ?? ''}';
    if (url.isEmpty || key.isEmpty) {
      throw UnknownException('The server did not issue an upload location');
    }

    await _uploader.putBytes(
      url: url,
      file: file,
      mime: mimeType,
      size: await file.length(),
    );
    // No confirm call: the key is filed by the save that stores the medicine.
    return key;
  }

  @override
  Future<void> delistMedicine(ShopMedicine medicine) =>
      updateMedicine(medicine.copyWith(isListed: false));

  // ─── Notifications ───────────────────────────────────────────────────────

  @override
  Future<List<ShopNotification>> notifications() async {
    final rows = await _api.getList(
      ApiConstants.notifications,
      query: {'limit': _pageSize},
    );
    return rows.map(shopNotificationFrom).toList();
  }

  @override
  Future<ShopStats> stats() async {
    final json = await _api.getMap(ApiConstants.pharmaciesMeStats);
    return ShopStats(
      newOrders: Api.integer(json['newOrders']),
      preparing: Api.integer(json['preparing']),
      newPrescriptions: Api.integer(json['newPrescriptions']),
      todaysEarnings: Api.majorUnits(json['todaysEarningsMinor']),
      lowStockItems: Api.integer(json['lowStockItems']),
      outOfStockItems: Api.integer(json['outOfStockItems']),
    );
  }
}
