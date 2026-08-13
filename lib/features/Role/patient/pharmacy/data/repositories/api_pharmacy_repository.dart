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

  @override
  Future<List<Medicine>> searchMedicines({
    String query = '',
    String? pharmacyId,
  }) async {
    final term = query.trim();
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
              ),
            )
            .toList()
          // Newest first: the order someone is waiting on is the one they opened
          // the screen to check.
          ..sort((a, b) => b.placedAt.compareTo(a.placedAt));
    return items;
  }
}
