import 'package:get/get.dart';

import '../../features/Role/patient/auth/data/datasources/auth_local_data_source.dart';
import '../../features/Role/patient/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/Role/patient/auth/data/datasources/mock_auth_remote_data_source.dart';
import '../../features/Role/patient/auth/data/repositories/auth_repository_impl.dart';
import '../../features/Role/patient/auth/domain/repositories/auth_repository.dart';
import '../../features/Role/patient/auth/domain/usecases/email_auth_usecases.dart';
import '../../features/Role/patient/auth/domain/usecases/password_recovery_usecases.dart';
import '../../features/Role/patient/auth/domain/usecases/phone_auth_usecases.dart';
import '../../features/Role/patient/auth/domain/usecases/registration_usecases.dart';
import '../../features/Role/patient/doctors/data/repositories/doctor_repository_impl.dart';
import '../../features/Role/patient/doctors/domain/repositories/doctor_repository.dart';
import '../../features/Role/patient/doctors/domain/usecases/doctor_usecases.dart';
import '../../features/Role/patient/home/data/datasources/home_remote_data_source.dart';
import '../../features/Role/patient/home/data/repositories/home_repository_impl.dart';
import '../../features/Role/patient/home/domain/repositories/home_repository.dart';
import '../../features/Role/patient/home/domain/usecases/home_usecases.dart';
import '../localization/localization_controller.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/storage_service.dart';

/// Wires the object graph once, before `runApp`.
///
/// Layering rule: **services → data sources → repositories → use cases**, all
/// registered permanently here because they are stateless and cheap. Screen
/// controllers are *not* registered here — they belong to route bindings so
/// they are created on entry and disposed on exit.
///
/// Swapping the mock backend for the real one is a single line: change
/// [_useMockBackend] to `false`.
class DependencyInjection {
  DependencyInjection._();

  /// Set to `false` once the Bienify API is reachable.
  static const bool _useMockBackend = true;

  static Future<void> init() async {
    // ─── Services ──────────────────────────────────────────────────────────
    final storage = StorageService();
    await storage.init();
    Get.put<StorageService>(storage, permanent: true);
    Get.put<ApiService>(ApiService(), permanent: true);
    Get.put<ConnectivityService>(ConnectivityService(), permanent: true);

    // ─── Localization ──────────────────────────────────────────────────────
    Get.put<LocalizationController>(
      LocalizationController(storage),
      permanent: true,
    );

    // ─── Auth data sources ─────────────────────────────────────────────────
    Get.put<AuthLocalDataSource>(AuthLocalDataSource(storage), permanent: true);
    Get.put<AuthRemoteDataSource>(
      _useMockBackend
          ? MockAuthRemoteDataSource()
          : ApiAuthRemoteDataSource(Get.find<ApiService>()),
      permanent: true,
    );

    // ─── Auth repository ───────────────────────────────────────────────────
    Get.put<AuthRepository>(
      AuthRepositoryImpl(
        remote: Get.find<AuthRemoteDataSource>(),
        local: Get.find<AuthLocalDataSource>(),
      ),
      permanent: true,
    );

    _registerAuthUseCases(Get.find<AuthRepository>());
    _registerHome();
    _registerDoctors();
  }

  static void _registerHome() {
    Get.put<HomeRemoteDataSource>(
      MockHomeRemoteDataSource(),
      permanent: true,
    );
    Get.put<HomeRepository>(
      HomeRepositoryImpl(remote: Get.find<HomeRemoteDataSource>()),
      permanent: true,
    );
    Get.put<GetHomeFeed>(
      GetHomeFeed(Get.find<HomeRepository>()),
      permanent: true,
    );
  }

  static void _registerDoctors() {
    Get.put<DoctorRepository>(const DoctorRepositoryImpl(), permanent: true);

    final repository = Get.find<DoctorRepository>();
    Get
      ..put<SearchDoctors>(SearchDoctors(repository), permanent: true)
      ..put<GetSpecialties>(GetSpecialties(repository), permanent: true)
      ..put<GetDoctorDetails>(GetDoctorDetails(repository), permanent: true)
      ..put<GetDoctorAvailability>(
        GetDoctorAvailability(repository),
        permanent: true,
      );
  }

  static void _registerAuthUseCases(AuthRepository repository) {
    Get
      ..put<RequestOtp>(RequestOtp(repository), permanent: true)
      ..put<VerifyOtp>(VerifyOtp(repository), permanent: true)
      ..put<LoginWithEmail>(LoginWithEmail(repository), permanent: true)
      ..put<SignInWithProvider>(SignInWithProvider(repository), permanent: true)
      ..put<Logout>(Logout(repository), permanent: true)
      ..put<SaveProfileDetails>(
        SaveProfileDetails(repository),
        permanent: true,
      )
      ..put<SaveCredentials>(SaveCredentials(repository), permanent: true)
      ..put<RequestPasswordResetOtp>(
        RequestPasswordResetOtp(repository),
        permanent: true,
      )
      ..put<VerifyPasswordResetOtp>(
        VerifyPasswordResetOtp(repository),
        permanent: true,
      )
      ..put<ResetPassword>(ResetPassword(repository), permanent: true);
  }

  static void clear() => Get.deleteAll(force: true);
}
