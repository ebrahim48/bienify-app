import '../services/incoming_call_notifier.dart';
import '../services/avatar_service.dart';
import '../services/device_location_service.dart';
import '../services/push_registration_service.dart';
import 'package:get/get.dart';
import '../widgets/app_snackbar.dart';
import '../utils/app_navigator.dart';
import '../routes/app_routes.dart';
import '../constants/app_strings.dart';

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
import '../../features/Role/patient/profile/data/repositories/api_account_repository.dart';
import '../../features/Role/patient/profile/data/repositories/mock_account_repository.dart';
import '../../features/Role/patient/profile/domain/repositories/account_repository.dart';
import '../../features/Role/patient/profile/domain/repositories/partner_repository.dart';
import '../../features/Role/patient/profile/data/repositories/api_partner_repository.dart';
import '../../features/Role/patient/profile/data/repositories/mock_partner_repository.dart';
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
import '../../features/Role/patient/cash_payment_process/data/repositories/api_cash_payment_repository.dart';
import '../../features/Role/patient/cash_payment_process/data/repositories/mock_cash_payment_repository.dart';
import '../../features/Role/patient/cash_payment_process/domain/repositories/cash_payment_repository.dart';
import '../../features/Role/patient/chat/data/repositories/api_conversation_repository.dart';
import '../../features/Role/patient/chat/data/repositories/mock_conversation_repository.dart';
import '../../features/Role/patient/notifications/data/repositories/api_notification_repository.dart';
import '../../features/Role/patient/notifications/data/repositories/mock_notification_repository.dart';
import '../../features/Role/patient/notifications/domain/repositories/notification_repository.dart';
import '../../features/Role/patient/chat/domain/repositories/conversation_repository.dart';
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
import '../../features/Role/rider_role/data/repositories/api_rider_repository.dart';
import '../../features/Role/rider_role/data/repositories/static_rider_repository.dart';
import '../../features/Role/rider_role/domain/repositories/rider_repository.dart';
import '../localization/localization_controller.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../network/mappers.dart';
import '../network/bienify_api.dart';
import '../network/attachment_uploader.dart';
import '../network/socket_service.dart';
import '../network/token_store.dart';
import '../services/api_service.dart';
import '../services/attachment_picker_service.dart';
import '../services/call_service.dart';
import '../services/message_delivery_service.dart';
import '../services/notification_inbox_service.dart';
import '../services/ringtone_service.dart';
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
    RingtoneService? ringtone,
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
    Get.put<BienifyApi>(
      BienifyApi(
        tokens: tokens,
        // A session that cannot be refreshed is over. Say so and return to the
        // start, rather than leaving the screen answering every tap with
        // "Missing or malformed Authorization header".
        onSessionExpired: () async {
          AppSnackbar.info(AppStrings.sessionExpired.tr);
          AppNavigator.resetTo(AppRoutes.onboarding);
        },
      ),
      permanent: true,
    );
    Get.put<ApiClient>(Get.find<BienifyApi>().client, permanent: true);

    // One socket for the whole app, not one per thread: the connection is the
    // expensive part, and rooms are what scope it to a conversation. Not
    // connected here — that waits until there is a session to authenticate
    // with, since the handshake carries the access token.
    Get.put<SocketService>(
      SocketService(
        tokens: tokens,
        // Lets the socket renew its own credential. It authenticates once in
        // the handshake and the access token lives fifteen minutes; nothing
        // else refreshes while a client is only sitting in a chat, so without
        // this the first drop after expiry took messaging down for the rest of
        // the session while the screen still looked connected.
        refreshTokens: Get.find<ApiClient>().refreshTokens,
      ),
      permanent: true,
    );
    // Registered before the auth repository below, whose session callbacks
    // reach for it.
    Get.put<PushRegistrationService>(
      PushRegistrationService(),
      permanent: true,
    );

    // Attachments: one picker and one uploader for the whole app, so every
    // attach button behaves the same and the plugins are referenced once.
    Get.put<AttachmentPickerService>(AttachmentPickerService(), permanent: true);
    Get.put<AttachmentUploader>(
      AttachmentUploader(Get.find<ApiClient>()),
      permanent: true,
    );

    Get.put<ConnectivityService>(ConnectivityService(), permanent: true);
    Get.put<PhotoPickerService>(PhotoPickerService(), permanent: true);

    // ─── Localization ──────────────────────────────────────────────────────
    Get.put<LocalizationController>(
      LocalizationController(storage),
      permanent: true,
    );

    // ─── Auth data sources ─────────────────────────────────────────────────
    Get.put<AuthLocalDataSource>(AuthLocalDataSource(storage), permanent: true);

    // Ringing, for the whole app.
    //
    // Permanent and listening from start-up because a call has to arrive on
    // whatever screen its recipient is already looking at — a screen-scoped
    // controller cannot hear one. Registered here, after the socket it listens
    // to and the session it reads the signed-in role from.
    Get.put<RingtoneService>(
      ringtone ?? AudioRingtoneService(),
      permanent: true,
    );
    Get.put<CallService>(
      CallService(
        socket: Get.find<SocketService>(),
        ringtone: Get.find<RingtoneService>(),
        auth: Get.find<AuthLocalDataSource>(),
        // Silent under mocks: a widget test has no platform channel to post a
        // notification through, and the plugin throws rather than no-ops.
        notifier: mock
            ? SilentIncomingCallNotifier()
            : SystemIncomingCallNotifier(),
      ),
      permanent: true,
    );

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
        // Signing in writes the bearer token every other repository's calls
        // are authenticated with.
        tokens: Get.find<TokenStore>(),
        // The socket follows the session: open once there is a token to
        // authenticate the handshake with, closed the moment there is not.
        // Both follow the session. The socket carries live updates while the
        // app is open; the push registration is what reaches the phone when it
        // is not, and withdrawing it on sign-out is what stops the next person
        // holding the device receiving this patient's reminders.
        onSessionStarted: () {
          Get.find<SocketService>().connect();
          Get.find<PushRegistrationService>().register();
        },
        onSessionEnded: () {
          Get.find<SocketService>().disconnect();
          Get.find<PushRegistrationService>().unregister();
        },
      ),
      permanent: true,
    );

    // A session restored from storage never passes through `_persist`, so it
    // would otherwise leave the app signed in with no socket until the next
    // sign-in.
    if (Get.find<TokenStore>().accessToken?.isNotEmpty ?? false) {
      Get.find<SocketService>().connect();
    }

    _registerAuthUseCases(Get.find<AuthRepository>());
    _registerHome(mock);
    _registerDoctors(mock);
    _registerAppointments(mock, clock);
    _registerPharmacy(mock);
    _registerVault(mock);
    _registerDoctorRole(mock);
    _registerShopRole(mock);
    _registerRiderRole(mock);
    _registerAccount(mock);
    _registerCashPayment(mock);
    _registerConversations(mock);
    _registerNotifications(mock);
  }

  static void _registerNotifications(bool mock) {
    Get.put<NotificationRepository>(
      mock
          ? MockNotificationRepository()
          : ApiNotificationRepository(Get.find<ApiClient>()),
      permanent: true,
    );

    // The middle tick. Permanent because delivery does not depend on which
    // screen the recipient is looking at — that is the whole difference
    // between delivered and read.
    Get.put<MessageDeliveryService>(
      MessageDeliveryService(
        socket: Get.find<SocketService>(),
        tokens: Get.find<TokenStore>(),
      ),
      permanent: true,
    );

    // Being told, rather than having to go and look. Permanent for the same
    // reason the call service is: a notification has to arrive on whatever
    // screen its recipient is already on, and the badge is on a header that
    // outlives every screen under it.
    //
    // Registered here rather than beside the socket, because it seeds the
    // badge from the repository above — which did not exist yet at that point,
    // so `Get.find` threw on start-up.
    Get.put<NotificationInboxService>(
      NotificationInboxService(
        socket: Get.find<SocketService>(),
        repository: Get.find<NotificationRepository>(),
        // Title and body on one line: `AppSnackbar.info` takes a single
        // message, and the two read as one sentence anyway.
        announce: (notification) => AppSnackbar.info(
          notification.body.isEmpty
              ? notification.title
              : '${notification.title} — ${notification.body}',
        ),
      ),
      permanent: true,
    );
  }

  static void _registerConversations(bool mock) {
    Get.put<ConversationRepository>(
      mock
          ? const MockConversationRepository()
          : ApiConversationRepository(
              Get.find<ApiClient>(),
              // Read on demand and not cached: which side of a thread a
              // message sits on depends on who is signed in, and that changes
              // when a role switches without the graph being rebuilt.
              myUserId: () async => Api.id(
                await Get.find<ApiClient>().getMap(ApiConstants.usersMe),
              ),
            ),
      permanent: true,
    );
  }

  static void _registerCashPayment(bool mock) {
    Get.put<CashPaymentRepository>(
      mock
          ? const MockCashPaymentRepository()
          : ApiCashPaymentRepository(Get.find<ApiClient>()),
      permanent: true,
    );
  }

  static void _registerAccount(bool mock) {
    // Registered after the account repository below, which it reads.
    Get.put<AccountRepository>(
      mock
          ? MockAccountRepository()
          : ApiAccountRepository(
              Get.find<ApiClient>(),
              Get.find<AttachmentUploader>(),
            ),
      permanent: true,
    );
    Get.put<AvatarService>(AvatarService(), permanent: true);
    Get.put<DeviceLocationService>(DeviceLocationService(), permanent: true);
    Get.put<PartnerRepository>(
      mock
          ? MockPartnerRepository()
          : ApiPartnerRepository(Get.find<ApiClient>()),
      permanent: true,
    );
  }

  static void _registerRiderRole(bool mock) {
    Get.put<RiderRepository>(
      mock
          ? const StaticRiderRepository()
          : ApiRiderRepository(
              Get.find<ApiClient>(),
              Get.find<AttachmentUploader>(),
            ),
      permanent: true,
    );
  }

  static void _registerDoctorRole(bool mock) {
    Get.put<DoctorPracticeRepository>(
      mock
          ? StaticDoctorPracticeRepository()
          : ApiDoctorPracticeRepository(
              Get.find<ApiClient>(),
              Get.find<AttachmentUploader>(),
            ),
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
          ? MockWalletRepository()
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
      mock
          ? MockVaultRepository()
          : ApiVaultRepository(
              Get.find<ApiClient>(),
              Get.find<AttachmentUploader>(),
            ),
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
      ..put<ResetPassword>(ResetPassword(repository), permanent: true)
      ..put<ChangePassword>(ChangePassword(repository), permanent: true);
  }

  static void clear() => Get.deleteAll(force: true);
}
