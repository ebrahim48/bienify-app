import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `pharmacies` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class PharmaciesApi {
  PharmaciesApi(this._c);

  final ApiClient _c;

  /// `GET /api/v1/pharmacies`
  Future<dynamic> getPharmacies({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.pharmacies, query: query);

  /// `GET /api/v1/pharmacies/best-matches`
  Future<dynamic> getBestmatches({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.pharmaciesBestMatches, query: query);

  /// `GET /api/v1/pharmacies/me`
  Future<dynamic> getMe({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.pharmaciesMe, query: query);

  /// `POST /api/v1/pharmacies/me`
  Future<dynamic> createMe({Object? body}) =>
      _c.post(ApiConstants.postPharmaciesMe, body: body);

  /// `POST /api/v1/pharmacies/me/medicines`
  Future<dynamic> createMemedicines({Object? body}) =>
      _c.post(ApiConstants.postPharmaciesMeMedicines, body: body);

  /// `PATCH /api/v1/pharmacies/me/medicines/:id`
  Future<dynamic> updateMemedicines({required String id, Object? body}) =>
      _c.patch(ApiConstants.updatePharmaciesMeMedicines(id), body: body);

  /// `GET /api/v1/pharmacies/me/stats`
  Future<dynamic> getMestats() => _c.get(ApiConstants.pharmaciesMeStats);

  /// `GET /api/v1/pharmacies/me/orders`
  Future<dynamic> getMeorders({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.pharmaciesMeOrders, query: query);

  /// `GET /api/v1/pharmacies/stock-alerts`
  Future<dynamic> getStockalerts({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.pharmaciesStockAlerts, query: query);
}
