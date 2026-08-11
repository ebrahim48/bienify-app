import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `medicine-orders` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class MedicineOrdersApi {
  MedicineOrdersApi(this._c);

  final ApiClient _c;

  /// `GET /api/v1/medicine-orders`
  Future<dynamic> getMedicineorders({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.medicineOrders, query: query);

  /// `POST /api/v1/medicine-orders`
  Future<dynamic> createMedicineorders({Object? body}) =>
      _c.post(ApiConstants.postMedicineOrders, body: body);

  /// `GET /api/v1/medicine-orders/:id`
  Future<dynamic> getMedicineorders2({
    required String id,
    Map<String, dynamic>? query,
  }) => _c.get(ApiConstants.medicineOrders2(id), query: query);

  /// `POST /api/v1/medicine-orders/:id/cancel`
  Future<dynamic> createCancel({required String id, Object? body}) =>
      _c.post(ApiConstants.postMedicineOrdersCancel(id), body: body);

  /// `POST /api/v1/medicine-orders/:id/pay`
  Future<dynamic> createPay({required String id, Object? body}) =>
      _c.post(ApiConstants.postMedicineOrdersPay(id), body: body);

  /// `PATCH /api/v1/medicine-orders/:id/status`
  Future<dynamic> updateStatus({required String id, Object? body}) =>
      _c.patch(ApiConstants.updateMedicineOrdersStatus(id), body: body);
}
