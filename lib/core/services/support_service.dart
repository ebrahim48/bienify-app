import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/api_constants.dart';
import '../constants/app_strings.dart';
import '../exceptions/app_exceptions.dart';
import '../network/api_client.dart';
import '../network/mappers.dart';
import '../widgets/app_snackbar.dart';

/// Where support actually is, and how to reach it.
///
/// The Health profile's two tiles printed "coming soon" because the app had no
/// idea: the platform keeps `platform.supportEmail` and `platform.supportPhone`
/// as settings, and `GET /config` now carries both. Blank means not
/// configured, and a tile that cannot do anything says so rather than opening
/// an empty mail composer.
class SupportService {
  SupportService({ApiClient? api}) : _api = api ?? Get.find<ApiClient>();

  final ApiClient _api;

  String? _email;
  String? _phone;

  /// Read once per run. The contacts change about as often as the company
  /// does, and a round trip per tap is a slower tile for no benefit.
  Future<void> _ensureLoaded() async {
    if (_email != null || _phone != null) return;
    final json = await _api.getMap(ApiConstants.clientConfig);
    _email = Api.str(json['supportEmail']);
    _phone = Api.str(json['supportPhone']);
  }

  Future<void> openChat() => _open(
    build: () => _email!.isEmpty
        ? null
        : Uri(
            scheme: 'mailto',
            path: _email,
            queryParameters: {'subject': AppStrings.supportEmailSubject.tr},
          ),
  );

  Future<void> call() => _open(
    build: () =>
        _phone!.isEmpty ? null : Uri(scheme: 'tel', path: _phone),
  );

  Future<void> _open({required Uri? Function() build}) async {
    try {
      await _ensureLoaded();
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    }

    final uri = build();
    if (uri == null) {
      AppSnackbar.info(AppStrings.supportUnavailable.tr);
      return;
    }

    // `launchUrl` returns false when the device has nothing registered for the
    // scheme — a tablet with no dialer, for instance.
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) AppSnackbar.info(AppStrings.supportUnavailable.tr);
  }
}
