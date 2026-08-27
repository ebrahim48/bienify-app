import '../../constants/api_constants.dart';
import '../api_client.dart';

/// The `config` endpoint.
///
/// The handful of platform settings a client legitimately needs.
/// `GET /admin/settings` returns everything and is admin-only, so the checkout
/// had no way to learn the delivery charge and used a constant instead.
class ConfigApi {
  ConfigApi(this._c);

  final ApiClient _c;

  /// `GET /api/v1/config`
  Future<dynamic> getConfig() => _c.get(ApiConstants.clientConfig);
}
