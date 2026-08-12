import 'package:get/get.dart';

import '../../features/Role/doctor_role/data/repositories/api_doctor_practice_repository.dart';
import '../../features/Role/doctor_role/data/repositories/static_doctor_practice_repository.dart';
import '../../features/Role/doctor_role/domain/repositories/doctor_practice_repository.dart';
import '../../features/Role/patient/appointments/data/repositories/api_appointment_repository.dart';
import '../../features/Role/patient/appointments/data/repositories/mock_appointment_repository.dart';
import '../../features/Role/patient/appointments/domain/repositories/appointment_repository.dart';
import '../../features/Role/patient/auth/data/datasources/auth_local_data_source.dart';
import '../../features/Role/patient/medical_vault/data/repositories/api_vault_repository.dart';
import '../../features/Role/patient/medical_vault/data/repositories/mock_vault_repository.dart';
import '../../features/Role/patient/medical_vault/domain/repositories/vault_repository.dart';
import '../../features/Role/patient/pharmacy/data/repositories/api_pharmacy_repository.dart';
import '../../features/Role/patient/pharmacy/data/repositories/mock_pharmacy_repository.dart';
import '../../features/Role/patient/pharmacy/domain/repositories/pharmacy_repository.dart';
import '../../features/Role/patient/wallet/data/repositories/api_wallet_repository.dart';
import '../../features/Role/patient/wallet/data/repositories/mock_wallet_repository.dart';
import '../../features/Role/patient/wallet/domain/repositories/wallet_repository.dart';
import '../../features/Role/patient/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/Role/patient/auth/data/datasources/mock_auth_remote_data_source.dart';
import '../../features/Role/patient/auth/data/repositories/auth_repository_impl.dart';
import '../../features/Role/patient/auth/domain/repositories/auth_repository.dart';
import '../../features/Role/patient/auth/domain/usecases/email_auth_usecases.dart';
import '../../features/Role/patient/auth/domain/usecases/password_recovery_usecases.dart';
import '../../features/Role/patient/auth/domain/usecases/phone_auth_usecases.dart';
import '../../features/Role/patient/auth/domain/usecases/registration_usecases.dart';
import '../../features/Role/patient/doctors/data/repositories/api_doctor_repository.dart';
import '../../features/Role/patient/doctors/data/repositories/doctor_repository_impl.dart';
import '../../features/Role/patient/doctors/domain/repositories/doctor_repository.dart';
import '../../features/Role/patient/doctors/domain/usecases/doctor_usecases.dart';
import '../../features/Role/patient/home/data/datasources/api_home_remote_data_source.dart';
import '../../features/Role/patient/home/data/datasources/home_remote_data_source.dart';
import '../../features/Role/patient/home/data/repositories/home_repository_impl.dart';
import '../../features/Role/patient/home/domain/repositories/home_repository.dart';
import '../../features/Role/patient/home/domain/usecases/home_usecases.dart';
import '../../features/Role/pharmacy_owner_role/data/repositories/api_pharmacy_shop_repository.dart';
import '../../features/Role/pharmacy_owner_role/data/repositories/static_pharmacy_shop_repository.dart';
import '../../features/Role/pharmacy_owner_role/domain/repositories/pharmacy_shop_repository.dart';
import '../localization/localization_controller.dart';
import '../network/api_client.dart';
import '../network/bienify_api.dart';
import '../network/token_store.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/photo_picker_service.dart';
import '../services/storage_service.dart';

/// Wires the object graph once, before `runApp`.
///
/// Layering rule: **services → data sources → repositories → use cases**, all
/// registered permanently here because they are stateless and cheap. Screen
/// controllers are *not* registered here — they belong to route bindings so
/// they are created on entry and disposed on exit.
///
/// Swapping the mock backend for the real one is a single line: change
/// [_useMockBackend] to `true`, or pass `useMocks` to [init].
class DependencyInjection {
  DependencyInjection._();

  /// Whether to serve screens from the in-memory fakes instead of the API.
  ///
  /// Defaults to the real backend. Build with
  /// `--dart-define=BIENIFY_USE_MOCKS=true` to walk the app without a server.
  static const bool _useMockBackend = bool.fromEnvironment('BIENIFY_USE_MOCKS');

  /// Wires the graph.
  ///
  /// [useMocks] overrides the build-time default. Widget and golden tests pass
  /// `true`: they assert on rendering, and a screen that reaches for a real
  /// server makes them depend on a backend being up and on whatever happens to
  /// be in its database that day.
  static Future<void> init({
    bool? useMocks,
    DateTime Function() clock = DateTime.now,
  }) async {
    final mock = useMocks ?? _useMockBackend;
    // ─── Services ──────────────────────────────────────────────────────────
    final storage = StorageService();
    await storage.init();
    Get.put<StorageService>(storage, permanent: true);
    Get.put<ApiService>(ApiService(), permanent: true);

    // The whole app shares one session, so one token store and one client.
    final tokens = PrefsTokenStore(storage);
    Get.put<TokenStore>(tokens, permanent: true);
    Get.put<BienifyApi>(BienifyApi(tokens: tokens), permanent: true);
    Get.put<ApiClient>(Get.find<BienifyApi>().client, permanent: true);
    Get.put<ConnectivityService>(ConnectivityService(), permanent: true);
    Get.put<PhotoPickerService>(PhotoPickerService(), permanent: true);

    // ─── Localization ──────────────────────────────────────────────────────
    Get.put<LocalizationController>(
      LocalizationController(storage),
      permanent: true,
    );

    // ─── Auth data sources ─────────────────────────────────────────────────
    Get.put<AuthLocalDataSource>(AuthLocalDataSource(storage), permanent: true);
    Get.put<AuthRemoteDataSource>(
      mock
          ? MockAuthRemoteDataSource()
          : ApiAuthRemoteDataSource(Get.find<ApiClient>()),
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
    _registerHome(mock);
    _registerDoctors(mock);
    _registerAppointments(mock, clock);
    _registerPharmacy(mock);
    _registerVault(mock);
    _registerDoctorRole(mock);
    _registerShopRole(mock);
  }

  static void _registerDoctorRole(bool mock) {
    Get.put<DoctorPracticeRepository>(
      mock
          ? const StaticDoctorPracticeRepository()
          : ApiDoctorPracticeRepository(Get.find<ApiClient>()),
      permanent: true,
    );
  }

  static void _registerShopRole(bool mock) {
    Get.put<PharmacyShopRepository>(
      mock
          ? const StaticPharmacyShopRepository()
          : ApiPharmacyShopRepository(Get.find<ApiClient>()),
      permanent: true,
    );
  }

  /// [clock] only reaches the mock: its fixtures are generated relative to
  /// "now", so a golden that pins today has to pin it here too, not just on
  /// the controller that groups the results.
  static void _registerAppointments(bool mock, DateTime Function() clock) {
    Get.put<WalletRepository>(
      mock
          ? const MockWalletRepository()
          : ApiWalletRepository(Get.find<ApiClient>()),
      permanent: true,
    );
    Get.put<AppointmentRepository>(
      mock
          ? MockAppointmentRepository(clock: clock)
          : ApiAppointmentRepository(Get.find<ApiClient>()),
      permanent: true,
    );
  }

  static void _registerPharmacy(bool mock) {
    Get.put<PharmacyRepository>(
      mock
          ? const MockPharmacyRepository()
          : ApiPharmacyRepository(Get.find<ApiClient>()),
      permanent: true,
    );
  }

  static void _registerVault(bool mock) {
    Get.put<VaultRepository>(
      mock ? MockVaultRepository() : ApiVaultRepository(Get.find<ApiClient>()),
      permanent: true,
    );
  }

  static void _registerHome(bool mock) {
    Get.put<HomeRemoteDataSource>(
      mock
          ? MockHomeRemoteDataSource()
          : ApiHomeRemoteDataSource(Get.find<ApiClient>()),
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

  static void _registerDoctors(bool mock) {
    Get.put<DoctorRepository>(
      mock
          ? const DoctorRepositoryImpl()
          : ApiDoctorRepository(Get.find<ApiClient>()),
      permanent: true,
    );

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
      ..put<SaveProfileDetails>(SaveProfileDetails(repository), permanent: true)
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
