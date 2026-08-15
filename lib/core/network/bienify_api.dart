import 'api_client.dart';
import 'apis.dart';
import 'token_store.dart';

/// The whole backend, grouped by domain.
///
/// Screens reach the network through this one object rather than constructing
/// their own Dio, so every call shares the same session, the same token
/// refresh, and the same error mapping.
class BienifyApi {
  BienifyApi({
    required TokenStore tokens,
    ApiClient? client,
    Future<void> Function()? onSessionExpired,
  }) : client =
           client ??
           ApiClient(tokens: tokens, onSessionExpired: onSessionExpired);

  final ApiClient client;

  late final AdminApi adminApi = AdminApi(client);
  late final AppointmentsApi appointmentsApi = AppointmentsApi(client);
  late final AuthApi authApi = AuthApi(client);
  late final CashIntentsApi cashIntentsApi = CashIntentsApi(client);
  late final ConsultationsApi consultationsApi = ConsultationsApi(client);
  late final DeliveriesApi deliveriesApi = DeliveriesApi(client);
  late final DiagnosticTestsApi diagnosticTestsApi = DiagnosticTestsApi(client);
  late final DoctorsApi doctorsApi = DoctorsApi(client);
  late final HealthApi healthApi = HealthApi(client);
  late final HomeApi homeApi = HomeApi(client);
  late final LabOrdersApi labOrdersApi = LabOrdersApi(client);
  late final MedicineOrdersApi medicineOrdersApi = MedicineOrdersApi(client);
  late final MedicinesApi medicinesApi = MedicinesApi(client);
  late final NotificationsApi notificationsApi = NotificationsApi(client);
  late final PartnerApplicationsApi partnerApplicationsApi =
      PartnerApplicationsApi(client);
  late final PaymentPointsApi paymentPointsApi = PaymentPointsApi(client);
  late final PaymentsApi paymentsApi = PaymentsApi(client);
  late final PharmaciesApi pharmaciesApi = PharmaciesApi(client);
  late final PrescriptionsApi prescriptionsApi = PrescriptionsApi(client);
  late final ReviewsApi reviewsApi = ReviewsApi(client);
  late final RidersApi ridersApi = RidersApi(client);
  late final TestingCentresApi testingCentresApi = TestingCentresApi(client);
  late final UsersApi usersApi = UsersApi(client);
  late final VaultApi vaultApi = VaultApi(client);
  late final WalletApi walletApi = WalletApi(client);

  /// The tokens backing this session.
  TokenStore get tokens => client.tokens;
}
