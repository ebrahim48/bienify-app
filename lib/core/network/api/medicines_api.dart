import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `medicines` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class MedicinesApi {
  MedicinesApi(this._c);

  final ApiClient _c;

  /// `GET /api/v1/medicines`
  Future<dynamic> getMedicines({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.medicines, query: query);
}
