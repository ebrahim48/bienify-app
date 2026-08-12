import 'package:get/get.dart';

import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/routes/home_for_role.dart';
import '../../../../../../core/utils/app_navigator.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

/// Decides where the app opens.
///
/// Order of precedence:
/// 1. a restored session → straight to that account's own shell,
/// 2. a first run → the location prompt,
/// 3. otherwise → onboarding.
class SplashController extends GetxController {
  SplashController({
    required AuthRepository repository,
    required AuthLocalDataSource local,
  }) : _repository = repository,
       _local = local;

  final AuthRepository _repository;
  final AuthLocalDataSource _local;

  /// How long the logo stays up; long enough to read, short enough not to
  /// feel like a stall.
  static const Duration _minimumDisplay = Duration(milliseconds: 1800);

  @override
  void onReady() {
    super.onReady();
    _resolveDestination();
  }

  Future<void> _resolveDestination() async {
    await Future<void>.delayed(_minimumDisplay);

    final session = _repository.currentSession;
    if (_repository.isSignedIn && session != null) {
      // A practitioner reopening the app lands on their dashboard, not in the
      // patient section — the same place signing in would have put them.
      AppNavigator.resetTo(homeForRole(session.user.role));
      return;
    }

    AppNavigator.resetTo(
      _local.hasSeenLocationPrompt
          ? AppRoutes.onboarding
          : AppRoutes.locationPermission,
    );
  }
}
