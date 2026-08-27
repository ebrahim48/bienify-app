import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/constants/api_constants.dart';
import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/network/mappers.dart';
import '../../domain/entities/pharmacy.dart';
import '../../domain/repositories/pharmacy_repository.dart';

/// The pharmacy catalogue and orders, served by the API.
class ApiPharmacyRepository implements PharmacyRepository {
  const ApiPharmacyRepository(this._api);

  final ApiClient _api;

  static const int _pageSize = 100;

  /// The server caps `search` at 64 characters.
  static const int _maxSearchLength = 64;

  static String _searchTerm(String query) {
    final term = query.trim();
    return term.length <= _maxSearchLength
        ? term
        : term.substring(0, _maxSearchLength).trim();
  }

  @override
  Future<List<Medicine>> searchMedicines({
    String query = '',
    String? pharmacyId,
  }) async {
    // Clamped to what the server accepts (`search` is min 1, max 64). A
    // longer name is rejected outright, and a search is better narrowed than
    // failed — the caller only wants the best match anyway.
    final term = _searchTerm(query);
    final rows = await _api.getList(
      ApiConstants.medicines,
      query: {
        if (term.isNotEmpty) 'search': term,
        if (pharmacyId != null && pharmacyId.isNotEmpty)
          'pharmacyId': pharmacyId,
        'limit': _pageSize,
      },
    );
    return rows.map(medicineFrom).toList();
  }

  @override
  Future<List<PharmacyStore>> stores({String query = ''}) async {
    final term = query.trim();
    final rows = await _api.getList(
      ApiConstants.pharmacies,
      query: {if (term.isNotEmpty) 'search': term, 'limit': _pageSize},
    );
    return rows.map(pharmacyFrom).toList();
  }

  @override
  Future<String> placeOrder({
    required String pharmacyId,
    required Map<String, int> quantitiesByMedicineId,
    required String deliveryAddress,
    String? prescriptionId,
  }) async {
    final data = await _api.postMap(
      ApiConstants.postMedicineOrders,
      body: {
        'pharmacyId': pharmacyId,
        'items': [
          for (final entry in quantitiesByMedicineId.entries)
            {'medicineId': entry.key, 'quantity': entry.value},
        ],
        'deliveryAddress': deliveryAddress,
        if (prescriptionId != null && prescriptionId.isNotEmpty)
          'prescriptionId': prescriptionId,
      },
    );
    return Api.id(data);
  }

  @override
  Future<void> payOrder(String orderId) async {
    await _api.post(ApiConstants.postMedicineOrdersPay(orderId));
  }

  @override
  Future<List<PharmacyOrder>> orders() async {
    final rows = await _api.getList(
      ApiConstants.medicineOrders,
      query: {'limit': _pageSize},
    );
    final items =
        rows
            .map(
              (row) => PharmacyOrder(
                id: Api.id(row),
                lines: Api.rows(row['items']).map(orderLineFrom).toList(),
                total: Api.majorUnits(row['totalMinor']),
                status: Api.str(row['status']),
                placedAt: Api.date(row['createdAt']),
                deliveryAddress: Api.str(row['deliveryAddress']),
                pharmacyName: Api.nameOf(row['pharmacyId'], ''),
                deliveryFee: Api.majorUnits(row['deliveryFeeMinor']),
              ),
            )
            .toList()
          // Newest first: the order someone is waiting on is the one they opened
          // the screen to check.
          ..sort((a, b) => b.placedAt.compareTo(a.placedAt));
    return items;
  }

  @override
  Future<DeliveryRoute> deliveryRoute(String deliveryId) async {
    final json = await _api.getMap(ApiConstants.deliveriesLocation(deliveryId));
    return deliveryRouteFrom(json);
  }

  @override
  Future<String?> deliveryIdForOrder(String orderId) async {
    // The order does not name its delivery, so this asks the delivery the
    // other way round. Returns null while the pharmacy has not dispatched it —
    // which is a normal state, not an error.
    try {
      final json = await _api.getMap(ApiConstants.medicineOrders2(orderId));
      final id = json['deliveryId'];
      return id == null ? null : Api.id(id);
    } on AppException {
      return null;
    }
  }

  @override
  Future<Courier?> courierFor(String deliveryId) async {
    final json = await _api.getMap(ApiConstants.deliveries(deliveryId));
    final rider = json['rider'];
    if (rider is! Map<String, dynamic>) return null;
    return Courier(
      id: Api.str(rider['id']),
      name: Api.str(rider['name'], AppStrings.courier.tr),
      photoUrl: Api.str(rider['avatarUrl']),
      rating: Api.decimal(rider['rating']),
      reviewCount: Api.integer(rider['reviewCount']),
      vehicleType: Api.str(rider['vehicleType']),
      city: Api.str(rider['city']),
    );
  }

  @override
  Future<double> deliveryCharge() async {
    final json = await _api.getMap(ApiConstants.clientConfig);
    return Api.majorUnits(json['deliveryFeeMinor']);
  }

  @override
  Future<List<PharmacyStore>> bestMatches(String prescriptionId) async {
    final rows = await _api.getList(
      ApiConstants.pharmaciesBestMatches,
      query: {'prescriptionId': prescriptionId},
    );
    return rows.map(pharmacyMatchFrom).toList();
  }
}