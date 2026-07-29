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
}
