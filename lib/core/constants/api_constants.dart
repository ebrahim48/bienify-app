/// Network configuration and every endpoint the backend serves.
///
/// Generated from the backend route table rather than written by hand: the
/// previous version listed nine auth paths, three of which the server does not
/// serve (`/auth/social`, `/auth/profile`, `/auth/credentials`), so those calls
/// could only ever 404.
///
/// Paths with an `:id` segment are functions, so a caller cannot forget to
/// substitute the id and send the literal string.
class ApiConstants {
  ApiConstants._();

  /// The deployed backend, so a device build reaches a server without being
  /// told where one is. `localhost` cannot be the default: on a phone or an
  /// emulator it resolves to the handset itself, so every call failed as a
  /// connection error and the app reported "No internet connection" on a
  /// perfectly good network.
  ///
  /// Override at build time to point at a local server:
  ///   flutter run --dart-define=BIENIFY_API_BASE_URL=http://10.0.2.2:3500
  static const String baseUrl = String.fromEnvironment(
    'BIENIFY_API_BASE_URL',
    defaultValue: 'https://benify.ssh.bd',
  );

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String _v1 = '/api/v1';

  // ─── Health ──────────────────────────────────────────────────────
  static const String health = '/health';
  static const String ready = '/ready';

  // ─── admin ───────────────────────────────────────────────────────
  static const String adminAppointments = '$_v1/admin/appointments';
  static const String adminDashboardApprovalQueues =
      '$_v1/admin/dashboard/approval-queues';
  static String updateAdminDashboardPharmaciesVerification(String id) =>
      '$_v1/admin/dashboard/pharmacies/$id/verification';
  static const String adminDashboardPharmaciesPending =
      '$_v1/admin/dashboard/pharmacies/pending';
  static const String adminDashboardRidersPending =
      '$_v1/admin/dashboard/riders/pending';
  static const String adminDashboardStats = '$_v1/admin/dashboard/stats';
  static String updateAdminDoctorsVerification(String id) =>
      '$_v1/admin/doctors/$id/verification';
  static const String adminDoctorsPending = '$_v1/admin/doctors/pending';
  static const String adminLabOrders = '$_v1/admin/lab-orders';
  static const String adminOrders = '$_v1/admin/orders';
  static const String adminPartnerApplications =
      '$_v1/admin/partner-applications';
  static String updateAdminPartnerApplications(String id) =>
      '$_v1/admin/partner-applications/$id';
  static const String adminPrescriptions = '$_v1/admin/prescriptions';
  static String adminReportsKind(String kind) => '$_v1/admin/reports/$kind';
  static String updateAdminRidersVerification(String id) =>
      '$_v1/admin/riders/$id/verification';
  static const String adminSettings = '$_v1/admin/settings';
  static const String putAdminSettings = '$_v1/admin/settings';
  static const String adminTests = '$_v1/admin/tests';
  static const String postAdminTests = '$_v1/admin/tests';
  static String deleteAdminTests(String id) => '$_v1/admin/tests/$id';
  static String updateAdminTests(String id) => '$_v1/admin/tests/$id';
  static const String adminTransactions = '$_v1/admin/transactions';
  static const String adminUsers = '$_v1/admin/users';
  static String updateAdminUsersStatus(String id) =>
      '$_v1/admin/users/$id/status';
  static const String adminWithdrawals = '$_v1/admin/withdrawals';
  static String updateAdminWithdrawals(String id) =>
      '$_v1/admin/withdrawals/$id';

  // ─── appointments ────────────────────────────────────────────────
  static const String appointments = '$_v1/appointments';
  static const String postAppointments = '$_v1/appointments';
  static String appointments2(String id) => '$_v1/appointments/$id';
  /// The doctor's refund for a lapsed consultation. Distinct from
  /// `postPaymentsAppointmentsRefund`, which is the operator's settlement of
  /// a cancellation.
  static String postAppointmentsRefund(String id) =>
      '$_v1/appointments/$id/refund';

  /// The patient's two remedies for a lapsed consultation. Mutually exclusive:
  /// rescheduling carries the fee across, so nothing is left to refund.
  static String postAppointmentsRequestRefund(String id) =>
      '$_v1/appointments/$id/request-refund';
  static String postAppointmentsReschedule(String id) =>
      '$_v1/appointments/$id/reschedule';
  static String postAppointmentsCancel(String id) =>
      '$_v1/appointments/$id/cancel';
  static String postAppointmentsComplete(String id) =>
      '$_v1/appointments/$id/complete';
  static String postAppointmentsNoShow(String id) =>
      '$_v1/appointments/$id/no-show';
  static String postAppointmentsStart(String id) =>
      '$_v1/appointments/$id/start';
  static const String appointmentsSlots = '$_v1/appointments/slots';

  // ─── auth ────────────────────────────────────────────────────────
  static const String postAuthLogin = '$_v1/auth/login';
  static const String postAuthLogout = '$_v1/auth/logout';
  static const String postAuthLogoutAll = '$_v1/auth/logout-all';
  static const String postAuthOtpRequest = '$_v1/auth/otp/request';
  static const String postAuthOtpVerify = '$_v1/auth/otp/verify';
  static const String postAuthPasswordChange = '$_v1/auth/password/change';
  static const String postAuthPasswordForgot = '$_v1/auth/password/forgot';
  static const String postAuthPasswordReset = '$_v1/auth/password/reset';
  static const String postAuthRefresh = '$_v1/auth/refresh';
  static const String postAuthRegister = '$_v1/auth/register';
  static const String postAuthCredentials = '$_v1/auth/credentials';
  static const String postAuthSocialApple = '$_v1/auth/social/apple';
  static const String postAuthSocialGoogle = '$_v1/auth/social/google';

  // ─── cash-intents ────────────────────────────────────────────────
  static const String cashIntents = '$_v1/cash-intents';
  static const String postCashIntents = '$_v1/cash-intents';
  static String cashIntents2(String id) => '$_v1/cash-intents/$id';
  static const String postCashIntentsConfirm = '$_v1/cash-intents/confirm';

  // ─── consultations ───────────────────────────────────────────────
  static String postConsultationsFollowUp(String id) =>
      '$_v1/consultations/$id/follow-up';
  static String postConsultationsJoin(String id) =>
      '$_v1/consultations/$id/join';

  /// Fresh credentials for a call already under way. Agora tokens expire, and
  /// a consultation outliving the TTL drops both parties without this.
  static String postConsultationsToken(String id) =>
      '$_v1/consultations/$id/token';
  /// A presigned PUT for a chat attachment. The device uploads straight to
  /// storage with it; the bytes never pass through this API.
  static String postConsultationsAttachmentUploadUrl(String id) =>
      '$_v1/consultations/$id/attachments/upload-url';
  static String consultationsMessages(String id) =>
      '$_v1/consultations/$id/messages';
  static String postConsultationsMessages(String id) =>
      '$_v1/consultations/$id/messages';
  static String updateConsultationsNotes(String id) =>
      '$_v1/consultations/$id/notes';
  static String postConsultationsPrescriptions(String id) =>
      '$_v1/consultations/$id/prescriptions';
  static const String consultationsThreads = '$_v1/consultations/threads';

  // ─── deliveries ──────────────────────────────────────────────────
  static const String postDeliveries = '$_v1/deliveries';
  static String deliveries(String id) => '$_v1/deliveries/$id';
  static String postDeliveriesClaim(String id) => '$_v1/deliveries/$id/claim';
  static String deliveriesLocation(String id) => '$_v1/deliveries/$id/location';
  static String updateDeliveriesLocation(String id) =>
      '$_v1/deliveries/$id/location';
  static String updateDeliveriesStatus(String id) =>
      '$_v1/deliveries/$id/status';
  static const String deliveriesAvailable = '$_v1/deliveries/available';
  /// The courier ↔ customer thread. Same shape as a consultation's messages,
  /// because it is the same conversation with a different pair of people.
  static String deliveriesMessages(String id) => '$_v1/deliveries/$id/messages';
  static String postDeliveriesMessages(String id) =>
      '$_v1/deliveries/$id/messages';
  static String postDeliveriesAttachmentUploadUrl(String id) =>
      '$_v1/deliveries/$id/attachments/upload-url';

  // ─── diagnostic-tests ────────────────────────────────────────────
  static const String diagnosticTests = '$_v1/diagnostic-tests';
  static const String clientConfig = '$_v1/config';

  // ─── doctors ─────────────────────────────────────────────────────
  static const String doctors = '$_v1/doctors';
  static String doctors2(String id) => '$_v1/doctors/$id';
  static const String doctorsMe = '$_v1/doctors/me';
  static const String postDoctorsMe = '$_v1/doctors/me';
  static const String putDoctorsMeAvailability = '$_v1/doctors/me/availability';
  static const String postDoctorsMeAvailabilityExceptions =
      '$_v1/doctors/me/availability/exceptions';
  static const String postDoctorsMeCredentials = '$_v1/doctors/me/credentials';
  static const String doctorsMeStats = '$_v1/doctors/me/stats';

  // ─── home ────────────────────────────────────────────────────────
  static const String homeFeed = '$_v1/home/feed';

  // ─── lab-orders ──────────────────────────────────────────────────
  static const String labOrders = '$_v1/lab-orders';
  static const String postLabOrders = '$_v1/lab-orders';
  static String postLabOrdersRespond(String id) =>
      '$_v1/lab-orders/$id/respond';
  static String updateLabOrdersReview(String id) =>
      '$_v1/lab-orders/$id/review';
  static String updateLabOrdersStatus(String id) =>
      '$_v1/lab-orders/$id/status';
  static String updateLabOrdersFacility(String id) =>
      '$_v1/lab-orders/$id/facility';
  static String postLabOrdersResultUploadUrl(String id) =>
      '$_v1/lab-orders/$id/result/upload-url';
  static String postLabOrdersResult(String id) => '$_v1/lab-orders/$id/result';

  // ─── medicine-orders ─────────────────────────────────────────────
  static const String medicineOrders = '$_v1/medicine-orders';
  static const String postMedicineOrders = '$_v1/medicine-orders';
  static String medicineOrders2(String id) => '$_v1/medicine-orders/$id';
  static String postMedicineOrdersCancel(String id) =>
      '$_v1/medicine-orders/$id/cancel';
  static String postMedicineOrdersPay(String id) =>
      '$_v1/medicine-orders/$id/pay';
  static String updateMedicineOrdersStatus(String id) =>
      '$_v1/medicine-orders/$id/status';

  // ─── medicines ───────────────────────────────────────────────────
  static const String medicines = '$_v1/medicines';

  // ─── notifications ───────────────────────────────────────────────
  static const String notifications = '$_v1/notifications';
  static String postNotificationsRead(String id) =>
      '$_v1/notifications/$id/read';
  static const String postNotificationsReadAll = '$_v1/notifications/read-all';
  static const String postNotificationsSend = '$_v1/notifications/send';
  static const String postNotificationsDevices = '$_v1/notifications/devices';
  static String deleteNotificationsDevices(String token) =>
      '$_v1/notifications/devices/$token';

  // ─── partner-applications ────────────────────────────────────────
  static const String postPartnerApplications = '$_v1/partner-applications';
  static const String partnerApplicationsMe = '$_v1/partner-applications/me';

  // ─── payment-points ──────────────────────────────────────────────
  static const String paymentPoints = '$_v1/payment-points';

  // ─── payments ────────────────────────────────────────────────────
  static String postPaymentsAppointmentsPay(String id) =>
      '$_v1/payments/appointments/$id/pay';
  static String postPaymentsAppointmentsRefund(String id) =>
      '$_v1/payments/appointments/$id/refund';

  // ─── pharmacies ──────────────────────────────────────────────────
  static const String pharmacies = '$_v1/pharmacies';
  static const String pharmaciesBestMatches = '$_v1/pharmacies/best-matches';
  static const String pharmaciesMe = '$_v1/pharmacies/me';
  static const String postPharmaciesMe = '$_v1/pharmacies/me';
  static const String postPharmaciesMeMedicines =
      '$_v1/pharmacies/me/medicines';
  static String updatePharmaciesMeMedicines(String id) =>
      '$_v1/pharmacies/me/medicines/$id';
  static const String pharmaciesMeStats = '$_v1/pharmacies/me/stats';
  static const String pharmaciesMeOrders = '$_v1/pharmacies/me/orders';
  static const String pharmaciesStockAlerts = '$_v1/pharmacies/stock-alerts';

  // ─── prescriptions ───────────────────────────────────────────────
  static const String prescriptions = '$_v1/prescriptions';
  static String prescriptions2(String id) => '$_v1/prescriptions/$id';

  // ─── reviews ─────────────────────────────────────────────────────
  static const String postReviews = '$_v1/reviews';
  static String reviewsDoctors(String id) => '$_v1/reviews/doctors/$id';
  static const String reviewsMe = '$_v1/reviews/me';
  static String reviewsPharmacies(String id) => '$_v1/reviews/pharmacies/$id';
  static String reviewsRiders(String id) => '$_v1/reviews/riders/$id';

  // ─── riders ──────────────────────────────────────────────────────
  static const String ridersMe = '$_v1/riders/me';
  static const String postRidersMe = '$_v1/riders/me';
  static const String updateRidersMeAvailability =
      '$_v1/riders/me/availability';
  static const String ridersMeDeliveries = '$_v1/riders/me/deliveries';
  static const String postRidersMeDocuments = '$_v1/riders/me/documents';

  // ─── testing-centres ─────────────────────────────────────────────
  static const String testingCentres = '$_v1/testing-centres';

  // ─── users ───────────────────────────────────────────────────────
  static const String usersMe = '$_v1/users/me';
  static const String updateUsersMe = '$_v1/users/me';
  static const String deleteUsersMe = '$_v1/users/me';
  static const String postUsersMeAvatarConfirm = '$_v1/users/me/avatar/confirm';
  static const String postUsersMeAvatarUploadUrl =
      '$_v1/users/me/avatar/upload-url';
  static const String postUsersMeDoorImageUploadUrl =
      '$_v1/users/me/address/door-image/upload-url';

  // ─── vault ───────────────────────────────────────────────────────
  static const String vaultHealthProfile = '$_v1/vault/health-profile';
  static const String putVaultHealthProfile = '$_v1/vault/health-profile';
  static const String vaultRecords = '$_v1/vault/records';
  static const String postVaultRecords = '$_v1/vault/records';
  static String vaultRecords2(String id) => '$_v1/vault/records/$id';
  static String vaultRecordsDownloadUrl(String id) =>
      '$_v1/vault/records/$id/download-url';
  static String postVaultRecordsShare(String id) =>
      '$_v1/vault/records/$id/share';
  static String deleteVaultRecordsShareDoctoruserid(
    String id,
    String doctorUserId,
  ) => '$_v1/vault/records/$id/share/$doctorUserId';
  static const String vaultRecordsSharedWithMe =
      '$_v1/vault/records/shared-with-me';
  static const String postDoctorsMeCredentialsUploadUrl =
      '$_v1/doctors/me/credentials/upload-url';
  static const String postRidersMeDocumentsUploadUrl =
      '$_v1/riders/me/documents/upload-url';

  static const String postVaultRecordsUploadUrl =
      '$_v1/vault/records/upload-url';

  // ─── wallet ──────────────────────────────────────────────────────
  static const String wallet = '$_v1/wallet';
  static const String walletCards = '$_v1/wallet/cards';
  static const String postWalletCards = '$_v1/wallet/cards';
  static String deleteWalletCards(String id) => '$_v1/wallet/cards/$id';
  static String updateWalletCardsDefault(String id) =>
      '$_v1/wallet/cards/$id/default';
  static const String walletEarnings = '$_v1/wallet/earnings';
  static const String walletPayoutAccounts = '$_v1/wallet/payout-accounts';
  static const String postWalletPayoutAccounts = '$_v1/wallet/payout-accounts';
  static String deleteWalletPayoutAccounts(String id) =>
      '$_v1/wallet/payout-accounts/$id';
  static String updateWalletPayoutAccountsDefault(String id) =>
      '$_v1/wallet/payout-accounts/$id/default';
  static const String postWalletTopup = '$_v1/wallet/topup';
  static const String walletTransactions = '$_v1/wallet/transactions';
  static const String walletWithdrawals = '$_v1/wallet/withdrawals';
  static const String postWalletWithdrawals = '$_v1/wallet/withdrawals';

  static Map<String, String> get headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  static Map<String, String> authorized(String token) => {
    ...headers,
    'Authorization': 'Bearer $token',
  };
}
