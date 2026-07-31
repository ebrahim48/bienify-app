import 'package:get/get.dart';

import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/utils/app_navigator.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';

/// Handles the "Allow your Location" prompt.
///
/// The screen is shown once per install; both answers continue to onboarding,
/// because location only personalises doctor search — it never gates sign-up.
///
/// **Wiring a real permission request:** replace the body of
/// [_requestSystemPermission] with a call into `permission_handler` (or
/// `geolocator`). Nothing else in the flow has to change.
class LocationPermissionController extends GetxController {
  LocationPermissionController({required AuthLocalDataSource local})
    : _local = local;

  final AuthLocalDataSource _local;

  final RxBool isRequesting = false.obs;

  Future<void> allow() async {
    if (isRequesting.value) return;
    isRequesting.value = true;
    try {
      await _requestSystemPermission();
      await _continue();
    } finally {
      isRequesting.value = false;
    }
  }

  Future<void> deny() => _continue();

  Future<void> _continue() async {
    await _local.markLocationPromptSeen();
    AppNavigator.resetTo(AppRoutes.onboarding);
  }

  /// Seam for the platform permission dialog.
  Future<void> _requestSystemPermission() async {}
}
