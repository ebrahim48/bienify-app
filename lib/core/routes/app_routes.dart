/// Every navigable destination in the app.
///
/// Screens navigate with `Get.toNamed(AppRoutes.login)` — never with a raw
/// string — so a renamed route is a compile error rather than a dead link.
abstract class AppRoutes {
  AppRoutes._();

  // ─── Boot ────────────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String locationPermission = '/location-permission';
  static const String onboarding = '/onboarding';

  // ─── Sign up ─────────────────────────────────────────────────────────────
  static const String phoneNumber = '/phone-number';
  static const String otp = '/otp';
  static const String profileSetup = '/profile-setup';
  static const String profileCredentials = '/profile-credentials';
  static const String signupSuccess = '/signup-success';

  // ─── Sign in ─────────────────────────────────────────────────────────────
  static const String login = '/login';

  // ─── Password recovery ───────────────────────────────────────────────────
  static const String forgotPassword = '/forgot-password';
  static const String newPassword = '/new-password';
  static const String passwordUpdated = '/password-updated';

  // ─── App ─────────────────────────────────────────────────────────────────
  static const String home = '/home';

  // ─── Discovery ───────────────────────────────────────────────────────────
  static const String search = '/search';
  static const String doctorList = '/doctor-list';
  static const String doctorDetails = '/doctor-details';

  // ─── Booking ─────────────────────────────────────────────────────────────
  static const String paymentSummary = '/payment-summary';
  static const String appointmentBooked = '/appointment-booked';

  // ─── Cash Payment Process ────────────────────────────────────────────────
  static const String howToPay = '/how-to-pay';
  static const String paymentPoints = '/payment-points';
  static const String paymentPending = '/payment-pending';
  static const String paymentConfirmed = '/payment-confirmed';

  // ─── Pharmacy ────────────────────────────────────────────────────────────
  static const String uploadPrescription = '/upload-prescription';
  static const String pharmacyMatches = '/pharmacy-matches';
  static const String selectMedicines = '/select-medicines';
  static const String pharmacyCart = '/pharmacy-cart';
  static const String pharmacyPayment = '/pharmacy-payment';
  static const String pharmacyOrder = '/pharmacy-order';
  static const String liveTracking = '/live-tracking';
  static const String deliveryFeedback = '/delivery-feedback';

  // ─── Consultation ────────────────────────────────────────────────────────
  static const String videoCall = '/video-call';
  static const String consultationHistory = '/consultation-history';

  // ─── Messaging ───────────────────────────────────────────────────────────
  static const String chat = '/chat';

  // ─── Profile ─────────────────────────────────────────────────────────────
  static const String profile = '/profile';
  static const String orderHistory = '/order-history';
  static const String wallet = '/wallet';
  static const String paymentOptions = '/payment-options';
  static const String addDebitCard = '/add-debit-card';
  static const String walletAccounts = '/wallet-accounts';
  static const String reviewShop = '/review-shop';
  static const String becomePartner = '/become-partner';
  static const String settings = '/settings';
  static const String changePassword = '/change-password';

  /// About Us, Terms and Privacy are one screen; the document arrives as the
  /// route argument.
  static const String legal = '/legal';

  // ─── Doctor ──────────────────────────────────────────────────────────────
  /// The practitioner-facing shell, with its own bottom navigation.
  static const String doctorHome = '/doctor';
  static const String doctorSetSchedule = '/doctor/set-schedule';
  static const String doctorAppointmentDetails = '/doctor/appointment';
  static const String doctorWritePrescription = '/doctor/write-prescription';

  /// The practitioner's side of the call and its summary. Both render the
  /// same screens as the patient's, with the role passed as the argument.
  static const String doctorVideoCall = '/doctor/video-call';
  static const String doctorConsultationDone = '/doctor/consultation-done';
  static const String doctorEarnings = '/doctor/earnings';
  static const String doctorEditProfile = '/doctor/edit-profile';

  /// Results to Review, and the ordering / reviewing flow behind it.
  static const String doctorResultsToReview = '/doctor/results-to-review';
  static const String doctorReviewPatient = '/doctor/review-patient';
  static const String doctorRequestTest = '/doctor/request-test';
  static const String doctorOrderDetail = '/doctor/order-detail';
  static const String doctorChooseReview = '/doctor/choose-review';
  static const String doctorReviewMessage = '/doctor/review-message';
  static const String doctorRequestFollowUp = '/doctor/request-follow-up';

  // ─── Pharmacy owner ──────────────────────────────────────────────────────
  /// The shop-facing shell, with its own bottom navigation.
  static const String shopHome = '/shop';
  static const String shopOrderDetails = '/shop/order';
  static const String shopNotifications = '/shop/notifications';
  static const String shopMedicineForm = '/shop/medicine-form';
  static const String shopEditProfile = '/shop/edit-profile';

  // ─── Rider ───────────────────────────────────────────────────────────────
  /// How It Works, and the application behind its Apply Now.
  static const String riderGuide = '/rider/guide';
  static const String riderApply = '/rider/apply';
  static const String riderReady = '/rider/ready';

  /// The courier-facing shell, with its own bottom navigation.
  static const String riderHome = '/rider';
  static const String riderTracking = '/rider/tracking';
  static const String riderDelivered = '/rider/delivered';
  static const String riderEditProfile = '/rider/edit-profile';

  // ─── Medical vault ───────────────────────────────────────────────────────
  static const String healthProfile = '/health-profile';
  static const String allPrescriptions = '/all-prescriptions';
  static const String allTestReports = '/all-test-reports';
  static const String prescriptionDetails = '/prescription-details';
  static const String pastAppointments = '/past-appointments';
  static const String testResults = '/test-results';
  static const String testOrder = '/test-order';
  static const String testingCentres = '/testing-centres';
  static const String uploadTestReport = '/upload-test-report';
  static const String resultsSubmitted = '/results-submitted';
  static const String reportReview = '/report-review';
}
